import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import {
  CREATED,
  MANUAL_DEPLOY,
  FAILED,
  DEPLOYING,
  REDEPLOYING,
  SUCCESS,
  STOPPING,
} from '~/vue_merge_request_widget/components/deployment/constants';
import eventHub from '~/vue_merge_request_widget/event_hub';
import DeploymentActions from '~/vue_merge_request_widget/components/deployment/deployment_actions.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import {
  actionButtonMocks,
  deploymentMockData,
  playDetails,
  retryDetails,
  mockRedeployProps,
} from './deployment_mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

describe('DeploymentAction component', () => {
  let wrapper;
  let executeActionSpy;

  const factory = (options = {}) => {
    wrapper = mount(DeploymentActions, options);
  };

  const findStopButton = () => wrapper.find('.js-stop-env');
  const findDeployButton = () => wrapper.find('.js-manual-deploy-action');
  const findRedeployButton = () => wrapper.find('.js-redeploy-action');

  beforeEach(() => {
    executeActionSpy = jest.spyOn(MRWidgetService, 'executeInlineAction');

    factory({
      propsData: {
        computedDeploymentStatus: CREATED,
        deployment: deploymentMockData,
      },
    });
  });

  afterEach(() => {
    confirmAction.mockReset();
  });

  describe('actions do not appear when conditions are unmet', () => {
    describe('when there is no stop_url', () => {
      beforeEach(() => {
        factory({
          propsData: {
            computedDeploymentStatus: CREATED,
            deployment: {
              ...deploymentMockData,
              stop_url: null,
            },
          },
        });
      });

      it('the stop button does not appear', () => {
        expect(findStopButton().exists()).toBe(false);
      });
    });

    describe('when there is no play_path in details', () => {
      it('the manual deploy button does not appear', () => {
        expect(findDeployButton().exists()).toBe(false);
      });
    });
  });

  describe('when conditions are met', () => {
    describe.each`
      configConst    | computedDeploymentStatus | displayConditionChanges | finderFn              | endpoint                                  | props
      ${STOPPING}    | ${CREATED}               | ${{}}                   | ${findStopButton}     | ${deploymentMockData.stop_url}            | ${{}}
      ${DEPLOYING}   | ${MANUAL_DEPLOY}         | ${playDetails}          | ${findDeployButton}   | ${playDetails.playable_build.play_path}   | ${{}}
      ${REDEPLOYING} | ${FAILED}                | ${{}}                   | ${findRedeployButton} | ${retryDetails.playable_build.retry_path} | ${mockRedeployProps}
      ${REDEPLOYING} | ${SUCCESS}               | ${{}}                   | ${findRedeployButton} | ${retryDetails.playable_build.retry_path} | ${mockRedeployProps}
    `(
      '$configConst action',
      ({
        configConst,
        computedDeploymentStatus,
        displayConditionChanges,
        finderFn,
        endpoint,
        props,
      }) => {
        describe(`${configConst} action`, () => {
          beforeEach(() => {
            factory({
              propsData: {
                computedDeploymentStatus,
                deployment: {
                  ...deploymentMockData,
                  details: displayConditionChanges,
                  ...props,
                },
              },
            });
          });

          it('the button is rendered', () => {
            expect(finderFn().exists()).toBe(true);
          });

          describe('when clicked', () => {
            describe('should show a confirm dialog but not call executeInlineAction when declined', () => {
              beforeEach(() => {
                executeActionSpy.mockResolvedValueOnce();
                confirmAction.mockResolvedValueOnce(false);
                finderFn().trigger('click');
              });

              it('should show the confirm dialog', () => {
                expect(confirmAction).toHaveBeenCalled();
                expect(confirmAction).toHaveBeenCalledWith(
                  actionButtonMocks[configConst].confirmMessage,
                  {
                    primaryBtnVariant: actionButtonMocks[configConst].buttonVariant,
                    primaryBtnText: actionButtonMocks[configConst].buttonText,
                  },
                );
              });

              it('should not execute the action', () => {
                expect(MRWidgetService.executeInlineAction).not.toHaveBeenCalled();
              });
            });

            describe('should show a confirm dialog and call executeInlineAction when accepted', () => {
              beforeEach(() => {
                executeActionSpy.mockResolvedValueOnce();
                confirmAction.mockResolvedValueOnce(true);
                finderFn().trigger('click');
              });

              it('should show the confirm dialog', () => {
                expect(confirmAction).toHaveBeenCalled();
                expect(confirmAction).toHaveBeenCalledWith(
                  actionButtonMocks[configConst].confirmMessage,
                  {
                    primaryBtnVariant: actionButtonMocks[configConst].buttonVariant,
                    primaryBtnText: actionButtonMocks[configConst].buttonText,
                  },
                );
              });

              it('should execute the action with expected URL', () => {
                expect(MRWidgetService.executeInlineAction).toHaveBeenCalled();
                expect(MRWidgetService.executeInlineAction).toHaveBeenCalledWith(endpoint);
              });

              it('should not throw an error', () => {
                expect(createAlert).not.toHaveBeenCalled();
              });

              describe('it should call the executeAction method', () => {
                beforeEach(async () => {
                  jest.spyOn(wrapper.vm, 'executeAction').mockImplementation();
                  jest.spyOn(eventHub, '$emit');

                  await waitForPromises();

                  confirmAction.mockResolvedValueOnce(true);
                  finderFn().trigger('click');
                });

                it('calls with the expected arguments', () => {
                  expect(wrapper.vm.executeAction).toHaveBeenCalled();
                  expect(wrapper.vm.executeAction).toHaveBeenCalledWith(
                    endpoint,
                    actionButtonMocks[configConst],
                  );
                });

                it('emits the FetchDeployments event', () => {
                  expect(eventHub.$emit).toHaveBeenCalledWith('FetchDeployments');
                });
              });

              describe('when executeInlineAction errors', () => {
                beforeEach(async () => {
                  executeActionSpy.mockRejectedValueOnce();
                  jest.spyOn(eventHub, '$emit');

                  await waitForPromises();

                  confirmAction.mockResolvedValueOnce(true);
                  finderFn().trigger('click');
                });

                it('should call createAlert with error message', () => {
                  expect(createAlert).toHaveBeenCalledWith({
                    message: actionButtonMocks[configConst].errorMessage,
                  });
                });

                it('emits the FetchDeployments event', () => {
                  expect(eventHub.$emit).toHaveBeenCalledWith('FetchDeployments');
                });
              });
            });
          });
        });
      },
    );
  });

  describe('redeploy action', () => {
    beforeEach(() => {
      factory({
        propsData: {
          computedDeploymentStatus: SUCCESS,
          deployment: {
            ...deploymentMockData,
            details: undefined,
            retry_url: retryDetails.playable_build.retry_path,
            environment_available: false,
          },
        },
      });
    });

    it('should display the redeploy button', () => {
      expect(findRedeployButton().exists()).toBe(true);
    });

    describe('when the redeploy button is clicked', () => {
      describe('should show a confirm dialog but not call executeInlineAction when declined', () => {
        beforeEach(() => {
          executeActionSpy.mockResolvedValueOnce();
          confirmAction.mockResolvedValueOnce(false);
          findRedeployButton().trigger('click');
        });

        it('should show the confirm dialog', () => {
          expect(confirmAction).toHaveBeenCalled();
          expect(confirmAction).toHaveBeenCalledWith(
            actionButtonMocks[REDEPLOYING].confirmMessage,
            {
              primaryBtnVariant: actionButtonMocks[REDEPLOYING].buttonVariant,
              primaryBtnText: actionButtonMocks[REDEPLOYING].buttonText,
            },
          );
        });

        it('should not execute the action', () => {
          expect(MRWidgetService.executeInlineAction).not.toHaveBeenCalled();
        });
      });

      describe('should show a confirm dialog and call executeInlineAction when accepted', () => {
        beforeEach(() => {
          executeActionSpy.mockResolvedValueOnce();
          confirmAction.mockResolvedValueOnce(true);
          findRedeployButton().trigger('click');
        });

        it('should show the confirm dialog', () => {
          expect(confirmAction).toHaveBeenCalled();
          expect(confirmAction).toHaveBeenCalledWith(
            actionButtonMocks[REDEPLOYING].confirmMessage,
            {
              primaryBtnVariant: actionButtonMocks[REDEPLOYING].buttonVariant,
              primaryBtnText: actionButtonMocks[REDEPLOYING].buttonText,
            },
          );
        });

        it('should not throw an error', () => {
          expect(createAlert).not.toHaveBeenCalled();
        });

        describe('it should call the executeAction method', () => {
          beforeEach(async () => {
            jest.spyOn(wrapper.vm, 'executeAction').mockImplementation();
            jest.spyOn(eventHub, '$emit');

            await waitForPromises();

            confirmAction.mockResolvedValueOnce(true);
            findRedeployButton().trigger('click');
          });

          it('calls with the expected arguments', () => {
            expect(wrapper.vm.executeAction).toHaveBeenCalled();
            expect(wrapper.vm.executeAction).toHaveBeenCalledWith(
              retryDetails.playable_build.retry_path,
              actionButtonMocks[REDEPLOYING],
            );
          });

          it('emits the FetchDeployments event', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('FetchDeployments');
          });
        });

        describe('when executeInlineAction errors', () => {
          beforeEach(async () => {
            executeActionSpy.mockRejectedValueOnce();
            jest.spyOn(eventHub, '$emit');

            await waitForPromises();

            confirmAction.mockResolvedValueOnce(true);
            findRedeployButton().trigger('click');
          });

          it('should call createAlert with error message', () => {
            expect(createAlert).toHaveBeenCalledWith({
              message: actionButtonMocks[REDEPLOYING].errorMessage,
            });
          });

          it('emits the FetchDeployments event', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('FetchDeployments');
          });
        });
      });
    });
  });
});
