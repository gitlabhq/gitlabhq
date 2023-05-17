import { start } from '~/code_review/signals';

import diffsEventHub from '~/diffs/event_hub';
import { EVT_MR_PREPARED } from '~/diffs/constants';
import { getDerivedMergeRequestInformation } from '~/diffs/utils/merge_request';

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
      let querySpy;
      let apolloSubscribeSpy;
      let subscribeSpy;
      let nextSpy;
      let unsubscribeSpy;
      let observable;

      beforeEach(() => {
        querySpy = jest.fn();
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

        querySpy.mockResolvedValue({
          data: { project: { mergeRequest: { id: 'gql:id:1', preparedAt: 'x' } } },
        });
        apolloSubscribeSpy.mockReturnValue(observable);

        apollo.query = querySpy;
        apollo.subscribe = apolloSubscribeSpy;

        callArgs.signalBus = io;
        callArgs.apolloClient = apollo;
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

        it('does not subscribe to any updates if the preparedAt value is already populated', async () => {
          await start(callArgs);

          expect(apolloSubscribeSpy).not.toHaveBeenCalled();
        });

        describe('if the merge request is still asynchronously preparing', () => {
          beforeEach(() => {
            querySpy.mockResolvedValue({
              data: { project: { mergeRequest: { id: 'gql:id:1', preparedAt: null } } },
            });
          });

          it('subscribes to updates', async () => {
            await start(callArgs);

            expect(apolloSubscribeSpy).toHaveBeenCalledWith(
              expect.objectContaining({ variables: { issuableId: 'gql:id:1' } }),
            );
            expect(observable.subscribe).toHaveBeenCalled();
          });

          describe('when the MR has been updated', () => {
            let emitSpy;
            let behavior;

            beforeEach(() => {
              emitSpy = jest.spyOn(diffsEventHub, '$emit');
              nextSpy.mockImplementation((data) => behavior?.(data));
              subscribeSpy.mockImplementation((handler) => {
                behavior = handler;

                return { unsubscribe: unsubscribeSpy };
              });
            });

            it('does nothing if the MR has not yet finished preparing', async () => {
              await start(callArgs);

              observable.next({ data: { mergeRequestMergeStatusUpdated: { preparedAt: null } } });

              expect(unsubscribeSpy).not.toHaveBeenCalled();
              expect(emitSpy).not.toHaveBeenCalled();
            });

            it('emits an event and unsubscribes when the MR is prepared', async () => {
              await start(callArgs);

              observable.next({ data: { mergeRequestMergeStatusUpdated: { preparedAt: 'x' } } });

              expect(unsubscribeSpy).toHaveBeenCalled();
              expect(emitSpy).toHaveBeenCalledWith(EVT_MR_PREPARED);
            });
          });
        });
      });
    });
  });
});
