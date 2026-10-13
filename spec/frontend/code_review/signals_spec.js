import waitForPromises from 'helpers/wait_for_promises';
import { start } from '~/code_review/signals';
import diffsEventHub from '~/diffs/event_hub';
import { EVT_MR_PREPARED, EVT_MR_DIFF_GENERATED } from '~/diffs/constants';
import { getDerivedMergeRequestInformation } from '~/diffs/utils/merge_request';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/diffs/utils/merge_request');

describe('~/code_review', () => {
  const io = diffsEventHub;

  beforeAll(() => {
    getDerivedMergeRequestInformation.mockImplementation(() => ({
      namespace: 'x',
      project: 'y',
      id: '1',
    }));
  });

  describe('start', () => {
    it.each`
      description                     | argument
      ${'no event hub is provided'}   | ${{}}
      ${'no parameters are provided'} | ${undefined}
    `('throws an error if $description', async ({ argument }) => {
      await expect(() => start(argument)).rejects.toThrow('signalBus is a required argument');
    });

    describe('observeMergeRequestFinishingPreparation', () => {
      const callArgs = {};
      const apollo = {};
      const preparingStatus = {
        data: { project: { mergeRequest: { id: 'gql:id:1', preparedAt: null } } },
      };
      const preparedStatus = {
        data: { project: { mergeRequest: { id: 'gql:id:1', preparedAt: 'x', commitCount: 3 } } },
      };
      // the server acknowledges a new subscription with an empty payload
      const acknowledgement = { data: { mergeRequestMergeStatusUpdated: null } };
      const preparedUpdate = { data: { mergeRequestMergeStatusUpdated: { preparedAt: 'x' } } };
      let querySpy;
      let apolloSubscribeSpy;
      let subscribeSpy;
      let unsubscribeSpy;
      let emitSpy;
      let behavior;

      // textContent is not `-` so observeMergeRequestDiffGenerated stays out of the way
      const renderTabCount = (preparing) => {
        setHTMLFixture(
          `<span class="js-changes-tab-count" data-gid="gql:id:1" data-preparing="${preparing}">0</span>`,
        );
      };

      const withoutAutomaticAcknowledgement = () => {
        subscribeSpy.mockImplementation((handler) => {
          behavior = handler;

          return { unsubscribe: unsubscribeSpy };
        });
      };

      beforeEach(() => {
        querySpy = jest.fn().mockResolvedValue(preparedStatus);
        unsubscribeSpy = jest.fn();
        subscribeSpy = jest.fn().mockImplementation((handler) => {
          behavior = handler;
          queueMicrotask(() => handler(acknowledgement));

          return { unsubscribe: unsubscribeSpy };
        });
        apolloSubscribeSpy = jest.fn().mockReturnValue({ subscribe: subscribeSpy });
        emitSpy = jest.spyOn(diffsEventHub, '$emit');

        apollo.query = querySpy;
        apollo.subscribe = apolloSubscribeSpy;

        callArgs.signalBus = io;
        callArgs.apolloClient = apollo;

        renderTabCount(false);
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('does not query at all if the page does not seem like a merge request', async () => {
        getDerivedMergeRequestInformation.mockImplementationOnce(() => ({}));

        await start(callArgs);

        expect(querySpy).not.toHaveBeenCalled();
        expect(apolloSubscribeSpy).not.toHaveBeenCalled();
      });

      describe('on a merge request page', () => {
        it('requests the preparedAt (and id) for the current merge request', async () => {
          await start(callArgs);

          expect(querySpy).toHaveBeenCalledWith(
            expect.objectContaining({
              variables: {
                projectPath: 'x/y',
                iid: '1',
              },
            }),
          );
        });

        describe('when the project does not exist', () => {
          beforeEach(() => {
            querySpy.mockResolvedValue({ data: { project: null } });
          });

          it('does not fail and quits silently', async () => {
            renderTabCount(true);

            await expect(start(callArgs)).resolves.toBeUndefined();

            expect(emitSpy).not.toHaveBeenCalled();
            expect(apolloSubscribeSpy).not.toHaveBeenCalled();
          });
        });

        describe('when the merge request is already prepared', () => {
          it('does not subscribe to preparation updates', async () => {
            await start(callArgs);

            expect(apolloSubscribeSpy).not.toHaveBeenCalled();
          });

          describe('and the page was not rendered while it was preparing', () => {
            it('emits EVT_MR_DIFF_GENERATED with the current status and never EVT_MR_PREPARED', async () => {
              await start(callArgs);

              expect(emitSpy).toHaveBeenCalledWith(
                EVT_MR_DIFF_GENERATED,
                preparedStatus.data.project.mergeRequest,
              );
              expect(emitSpy).not.toHaveBeenCalledWith(EVT_MR_PREPARED);
            });
          });

          describe('and the page was rendered while it was preparing', () => {
            beforeEach(() => {
              renderTabCount(true);
            });

            it('emits EVT_MR_PREPARED', async () => {
              await start(callArgs);

              expect(emitSpy).toHaveBeenCalledWith(EVT_MR_PREPARED);
            });

            it('emits EVT_MR_DIFF_GENERATED with the status response without querying again', async () => {
              await start(callArgs);
              await waitForPromises();

              expect(querySpy).toHaveBeenCalledTimes(1);
              expect(emitSpy).toHaveBeenCalledWith(
                EVT_MR_DIFF_GENERATED,
                preparedStatus.data.project.mergeRequest,
              );
            });
          });
        });

        describe('when the merge request is still preparing', () => {
          beforeEach(() => {
            querySpy.mockResolvedValue(preparingStatus);
          });

          it('subscribes to preparation updates after querying the current status', async () => {
            await start(callArgs);

            expect(apolloSubscribeSpy).toHaveBeenCalledWith(
              expect.objectContaining({ variables: { issuableId: 'gql:id:1' } }),
            );
            expect(querySpy.mock.invocationCallOrder[0]).toBeLessThan(
              apolloSubscribeSpy.mock.invocationCallOrder[0],
            );
          });

          it('does not emit anything while the merge request is still preparing', async () => {
            await start(callArgs);
            await waitForPromises();

            expect(emitSpy).not.toHaveBeenCalled();
            expect(unsubscribeSpy).not.toHaveBeenCalled();
          });

          describe('when the page was not rendered while the merge request was preparing', () => {
            it('does not re-read the status when the subscription is acknowledged', async () => {
              await start(callArgs);
              await waitForPromises();

              expect(querySpy).toHaveBeenCalledTimes(1);
            });
          });

          describe('when the page was rendered while the merge request was preparing', () => {
            beforeEach(() => {
              renderTabCount(true);
              withoutAutomaticAcknowledgement();
            });

            it('re-reads the status with network-only fetch policy once the subscription is acknowledged', async () => {
              await start(callArgs);

              expect(querySpy).toHaveBeenCalledTimes(1);

              behavior(acknowledgement);
              await waitForPromises();

              expect(querySpy).toHaveBeenCalledTimes(2);
              expect(querySpy).toHaveBeenLastCalledWith(
                expect.objectContaining({ fetchPolicy: 'network-only' }),
              );
            });

            it('re-reads the status only once', async () => {
              await start(callArgs);

              behavior(acknowledgement);
              behavior({ data: { mergeRequestMergeStatusUpdated: { preparedAt: null } } });
              await waitForPromises();

              expect(querySpy).toHaveBeenCalledTimes(2);
            });

            describe('when the re-read still reports the merge request as preparing', () => {
              it('keeps the subscription and emits nothing', async () => {
                await start(callArgs);

                behavior(acknowledgement);
                await waitForPromises();

                expect(emitSpy).not.toHaveBeenCalled();
                expect(unsubscribeSpy).not.toHaveBeenCalled();
              });
            });

            describe('when the re-read reports the merge request as prepared', () => {
              beforeEach(() => {
                querySpy
                  .mockResolvedValueOnce(preparingStatus)
                  .mockResolvedValueOnce(preparedStatus);
              });

              it('emits EVT_MR_PREPARED and unsubscribes', async () => {
                await start(callArgs);

                behavior(acknowledgement);
                await waitForPromises();

                expect(emitSpy).toHaveBeenCalledWith(EVT_MR_PREPARED);
                expect(unsubscribeSpy).toHaveBeenCalled();
              });

              it('emits EVT_MR_DIFF_GENERATED with the re-read status without querying again', async () => {
                await start(callArgs);

                behavior(acknowledgement);
                await waitForPromises();

                expect(querySpy).toHaveBeenCalledTimes(2);
                expect(emitSpy).toHaveBeenCalledWith(
                  EVT_MR_DIFF_GENERATED,
                  preparedStatus.data.project.mergeRequest,
                );
              });
            });

            describe('when the re-read fails', () => {
              it('does not throw and keeps the subscription', async () => {
                querySpy
                  .mockResolvedValueOnce(preparingStatus)
                  .mockRejectedValueOnce(new Error('network error'));

                await start(callArgs);

                behavior(acknowledgement);
                await waitForPromises();

                expect(emitSpy).not.toHaveBeenCalled();
                expect(unsubscribeSpy).not.toHaveBeenCalled();
              });
            });

            it('acts once when the subscription reports prepared while the re-read is in flight', async () => {
              let resolveRecheck;
              querySpy.mockResolvedValueOnce(preparingStatus).mockImplementationOnce(
                () =>
                  new Promise((resolve) => {
                    resolveRecheck = resolve;
                  }),
              );

              await start(callArgs);

              behavior(acknowledgement);
              await waitForPromises();
              behavior(preparedUpdate);
              resolveRecheck(preparedStatus);
              await waitForPromises();

              expect(
                emitSpy.mock.calls.filter(([event]) => event === EVT_MR_PREPARED),
              ).toHaveLength(1);
              expect(unsubscribeSpy).toHaveBeenCalledTimes(1);
            });
          });

          describe('when the subscription reports the merge request as prepared', () => {
            it('emits EVT_MR_PREPARED and unsubscribes', async () => {
              await start(callArgs);

              behavior(preparedUpdate);
              await waitForPromises();

              expect(unsubscribeSpy).toHaveBeenCalled();
              expect(emitSpy).toHaveBeenCalledWith(EVT_MR_PREPARED);
            });

            it('ignores updates without preparedAt', async () => {
              await start(callArgs);

              behavior({ data: { mergeRequestMergeStatusUpdated: { preparedAt: null } } });
              await waitForPromises();

              expect(emitSpy).not.toHaveBeenCalled();
            });

            it('re-queries the MR with network-only fetch policy and emits fresh data', async () => {
              querySpy.mockResolvedValueOnce(preparingStatus).mockResolvedValueOnce(preparedStatus);

              await start(callArgs);

              behavior(preparedUpdate);
              await waitForPromises();

              expect(querySpy).toHaveBeenCalledTimes(2);
              expect(querySpy).toHaveBeenLastCalledWith(
                expect.objectContaining({ fetchPolicy: 'network-only' }),
              );
              expect(emitSpy).toHaveBeenCalledWith(
                EVT_MR_DIFF_GENERATED,
                preparedStatus.data.project.mergeRequest,
              );
            });

            it('does not throw and does not emit EVT_MR_DIFF_GENERATED when the re-query fails', async () => {
              querySpy
                .mockResolvedValueOnce(preparingStatus)
                .mockRejectedValueOnce(new Error('network error'));

              await start(callArgs);

              behavior(preparedUpdate);
              await waitForPromises();

              expect(emitSpy).toHaveBeenCalledWith(EVT_MR_PREPARED);
              expect(emitSpy).not.toHaveBeenCalledWith(EVT_MR_DIFF_GENERATED, expect.anything());
            });
          });
        });
      });
    });

    describe('observeMergeRequestDiffGenerated', () => {
      const callArgs = {};
      const apollo = {};
      let apolloSubscribeSpy;
      let subscribeSpy;
      let unsubscribeSpy;
      let nextSpy;
      let observable;
      let emitSpy;
      let behavior;

      beforeEach(() => {
        apolloSubscribeSpy = jest.fn();
        subscribeSpy = jest.fn();
        unsubscribeSpy = jest.fn();
        nextSpy = jest.fn();
        observable = {
          next: nextSpy,
          subscribe: subscribeSpy.mockReturnValue({
            unsubscribe: unsubscribeSpy,
          }),
        };
        emitSpy = jest.spyOn(diffsEventHub, '$emit');
        nextSpy.mockImplementation((data) => behavior?.(data));
        subscribeSpy.mockImplementation((handler) => {
          behavior = handler;

          return { unsubscribe: unsubscribeSpy };
        });

        apolloSubscribeSpy.mockReturnValue(observable);

        apollo.subscribe = apolloSubscribeSpy;

        callArgs.signalBus = io;
        callArgs.apolloClient = apollo;

        getDerivedMergeRequestInformation.mockImplementationOnce(() => ({}));
      });

      beforeEach(() => {
        setHTMLFixture('<div class="js-changes-tab-count" data-gid="1">-</div>');
      });

      afterEach(() => {
        window.gon.features = {};
        resetHTMLFixture();
      });

      it('does not subscribe if the page is not a merge request', async () => {
        await start(callArgs);

        expect(apolloSubscribeSpy).toHaveBeenCalledWith(
          expect.objectContaining({ variables: { issuableId: '1' } }),
        );
        expect(observable.subscribe).toHaveBeenCalled();
      });

      it('does not emit an event when mergeRequestDiffGenerated is null', async () => {
        await start(callArgs);

        observable.next({ data: { mergeRequestDiffGenerated: null } });

        expect(emitSpy).not.toHaveBeenCalled();
      });

      it('emits an event', async () => {
        await start(callArgs);

        observable.next({ data: { mergeRequestDiffGenerated: { totalCount: 1 } } });

        expect(emitSpy).toHaveBeenCalledWith(EVT_MR_DIFF_GENERATED, { totalCount: 1 });
      });

      it('unsubscribes from subscription', async () => {
        await start(callArgs);

        observable.next({ data: { mergeRequestDiffGenerated: { totalCount: 1 } } });

        expect(unsubscribeSpy).toHaveBeenCalled();
      });
    });
  });
});
