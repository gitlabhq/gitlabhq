import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { trimText } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import autoMergeEnabledComponent from '~/vue_merge_request_widget/components/states/mr_widget_auto_merge_enabled.vue';
import { MWPS_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';
import eventHub from '~/vue_merge_request_widget/event_hub';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

let wrapper;
let mergeRequestWidgetGraphqlEnabled = false;

function convertPropsToGraphqlState(props) {
  return {
    autoMergeStrategy: props.autoMergeStrategy,
    cancelAutoMergePath: 'http://text.com',
    mergeUser: {
      id: props.mergeUserId,
      ...props.setToAutoMergeBy,
    },
    targetBranch: props.targetBranch,
    targetBranchCommitsPath: props.targetBranchPath,
    shouldRemoveSourceBranch: props.shouldRemoveSourceBranch,
    forceRemoveSourceBranch: props.shouldRemoveSourceBranch,
    userPermissions: {
      removeSourceBranch: props.canRemoveSourceBranch,
    },
  };
}

function factory(propsData, stateOverride = {}) {
  let state = {};

  if (mergeRequestWidgetGraphqlEnabled) {
    state = { ...convertPropsToGraphqlState(propsData), ...stateOverride };
  }

  wrapper = extendedWrapper(
    shallowMount(autoMergeEnabledComponent, {
      propsData: {
        mr: propsData,
        service: new MRWidgetService({}),
      },
      data() {
        return { state };
      },
      provide: { glFeatures: { mergeRequestWidgetGraphql: mergeRequestWidgetGraphqlEnabled } },
      mocks: {
        $apollo: {
          queries: {
            state: { loading: false },
          },
        },
      },
    }),
  );
}

const targetBranchPath = '/foo/bar';
const targetBranch = 'foo';
const sha = '1EA2EZ34';
const defaultMrProps = () => ({
  shouldRemoveSourceBranch: false,
  canRemoveSourceBranch: true,
  canCancelAutomaticMerge: true,
  mergeUserId: 1,
  currentUserId: 1,
  setToAutoMergeBy: {},
  sha,
  targetBranchPath,
  targetBranch,
  autoMergeStrategy: MWPS_MERGE_STRATEGY,
});

describe('MRWidgetAutoMergeEnabled', () => {
  let oldWindowGl;

  beforeEach(() => {
    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    oldWindowGl = window.gl;
    window.gl = {
      mrWidgetData: {
        defaultAvatarUrl: 'no_avatar.png',
      },
    };
  });

  afterEach(() => {
    window.gl = oldWindowGl;
    wrapper.destroy();
    wrapper = null;
  });

  [true, false].forEach((mergeRequestWidgetGraphql) => {
    describe(`when graphql is ${mergeRequestWidgetGraphql ? 'enabled' : 'disabled'}`, () => {
      beforeEach(() => {
        mergeRequestWidgetGraphqlEnabled = mergeRequestWidgetGraphql;
      });

      describe('computed', () => {
        describe('canRemoveSourceBranch', () => {
          it('should return true when user is able to remove source branch', () => {
            factory({
              ...defaultMrProps(),
            });

            expect(wrapper.findByTestId('removeSourceBranchButton').exists()).toBe(true);
          });

          it.each`
            mergeUserId | currentUserId
            ${2}        | ${1}
            ${1}        | ${2}
          `(
            'should return false when user id is not the same with who set the MWPS',
            ({ mergeUserId, currentUserId }) => {
              factory({
                ...defaultMrProps(),
                mergeUserId,
                currentUserId,
              });

              expect(wrapper.findByTestId('removeSourceBranchButton').exists()).toBe(false);
            },
          );

          it('should not find "Delete" button when shouldRemoveSourceBranch set to true', () => {
            factory({
              ...defaultMrProps(),
              shouldRemoveSourceBranch: true,
            });

            expect(wrapper.findByTestId('removeSourceBranchButton').exists()).toBe(false);
          });

          it('should find "Delete" button when shouldRemoveSourceBranch overrides state.forceRemoveSourceBranch', () => {
            factory(
              {
                ...defaultMrProps(),
                shouldRemoveSourceBranch: false,
              },
              {
                forceRemoveSourceBranch: true,
              },
            );

            expect(wrapper.findByTestId('removeSourceBranchButton').exists()).toBe(true);
          });

          it('should find "Delete" button when shouldRemoveSourceBranch set to false', () => {
            factory({
              ...defaultMrProps(),
              shouldRemoveSourceBranch: false,
            });

            expect(wrapper.findByTestId('removeSourceBranchButton').exists()).toBe(true);
          });

          it('should return false if user is not able to remove the source branch', () => {
            factory({
              ...defaultMrProps(),
              canRemoveSourceBranch: false,
            });

            expect(wrapper.findByTestId('removeSourceBranchButton').exists()).toBe(false);
          });
        });

        describe('statusTextBeforeAuthor', () => {
          it('should return "Set by" if the MWPS is selected', () => {
            factory({
              ...defaultMrProps(),
              autoMergeStrategy: MWPS_MERGE_STRATEGY,
            });

            expect(wrapper.findByTestId('beforeStatusText').text()).toBe('Set by');
          });
        });

        describe('statusTextAfterAuthor', () => {
          it('should return "to be merged automatically..." if MWPS is selected', () => {
            factory({
              ...defaultMrProps(),
              autoMergeStrategy: MWPS_MERGE_STRATEGY,
            });

            expect(wrapper.findByTestId('afterStatusText').text()).toBe(
              'to be merged automatically when the pipeline succeeds',
            );
          });
        });

        describe('cancelButtonText', () => {
          it('should return "Cancel" if MWPS is selected', () => {
            factory({
              ...defaultMrProps(),
              autoMergeStrategy: MWPS_MERGE_STRATEGY,
            });

            expect(wrapper.findByTestId('cancelAutomaticMergeButton').text()).toBe('Cancel');
          });
        });
      });

      describe('methods', () => {
        describe('cancelAutomaticMerge', () => {
          it('should set flag and call service then tell main component to update the widget with data', (done) => {
            factory({
              ...defaultMrProps(),
            });
            const mrObj = {
              is_new_mr_data: true,
            };
            jest.spyOn(wrapper.vm.service, 'cancelAutomaticMerge').mockReturnValue(
              new Promise((resolve) => {
                resolve({
                  data: mrObj,
                });
              }),
            );

            wrapper.vm.cancelAutomaticMerge();
            setImmediate(() => {
              expect(wrapper.vm.isCancellingAutoMerge).toBeTruthy();
              if (mergeRequestWidgetGraphql) {
                expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
              } else {
                expect(eventHub.$emit).toHaveBeenCalledWith('UpdateWidgetData', mrObj);
              }
              done();
            });
          });
        });

        describe('removeSourceBranch', () => {
          it('should set flag and call service then request main component to update the widget', (done) => {
            factory({
              ...defaultMrProps(),
            });
            jest.spyOn(wrapper.vm.service, 'merge').mockReturnValue(
              Promise.resolve({
                data: {
                  status: MWPS_MERGE_STRATEGY,
                },
              }),
            );

            wrapper.vm.removeSourceBranch();
            setImmediate(() => {
              expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
              expect(wrapper.vm.service.merge).toHaveBeenCalledWith({
                sha,
                auto_merge_strategy: MWPS_MERGE_STRATEGY,
                should_remove_source_branch: true,
              });
              done();
            });
          });
        });
      });

      describe('template', () => {
        it('should have correct elements', () => {
          factory({
            ...defaultMrProps(),
          });

          expect(wrapper.element).toMatchSnapshot();
        });

        it('should disable cancel auto merge button when the action is in progress', async () => {
          factory({
            ...defaultMrProps(),
          });
          wrapper.setData({
            isCancellingAutoMerge: true,
          });

          await nextTick();

          expect(wrapper.find('.js-cancel-auto-merge').attributes('disabled')).toBe('disabled');
        });

        it('should show source branch will be deleted text when it source branch set to remove', () => {
          factory({
            ...defaultMrProps(),
            shouldRemoveSourceBranch: true,
          });

          const normalizedText = wrapper.text().replace(/\s+/g, ' ');

          expect(normalizedText).toContain('The source branch will be deleted');
          expect(normalizedText).not.toContain('The source branch will not be deleted');
        });

        it('should not show delete source branch button when user not able to delete source branch', () => {
          factory({
            ...defaultMrProps(),
            currentUserId: 4,
          });

          expect(wrapper.find('.js-remove-source-branch').exists()).toBe(false);
        });

        it('should disable delete source branch button when the action is in progress', async () => {
          factory({
            ...defaultMrProps(),
          });
          wrapper.setData({
            isRemovingSourceBranch: true,
          });

          await nextTick();

          expect(wrapper.find('.js-remove-source-branch').attributes('disabled')).toBe('disabled');
        });

        it('should render the status text as "...to merged automatically" if MWPS is selected', () => {
          factory({
            ...defaultMrProps(),
            autoMergeStrategy: MWPS_MERGE_STRATEGY,
          });

          const statusText = trimText(wrapper.find('.js-status-text-after-author').text());

          expect(statusText).toBe('to be merged automatically when the pipeline succeeds');
        });

        it('should render the cancel button as "Cancel" if MWPS is selected', () => {
          factory({
            ...defaultMrProps(),
            autoMergeStrategy: MWPS_MERGE_STRATEGY,
          });

          const cancelButtonText = trimText(wrapper.find('.js-cancel-auto-merge').text());

          expect(cancelButtonText).toBe('Cancel');
        });
      });
    });
  });
});
