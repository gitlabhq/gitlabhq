import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import WidgetRebase from '~/vue_merge_request_widget/components/states/mr_widget_rebase.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import ActionsButton from '~/vue_shared/components/actions_button.vue';
import {
  REBASE_BUTTON_KEY,
  REBASE_WITHOUT_CI_BUTTON_KEY,
} from '~/vue_merge_request_widget/constants';

let wrapper;

function createWrapper(propsData, mergeRequestWidgetGraphql) {
  wrapper = shallowMount(WidgetRebase, {
    propsData,
    data() {
      return {
        state: {
          rebaseInProgress: propsData.mr.rebaseInProgress,
          targetBranch: propsData.mr.targetBranch,
          userPermissions: {
            pushToSourceBranch: propsData.mr.canPushToSourceBranch,
          },
        },
      };
    },
    provide: { glFeatures: { mergeRequestWidgetGraphql } },
    mocks: {
      $apollo: {
        queries: {
          state: { loading: false },
        },
      },
    },
  });
}

describe('Merge request widget rebase component', () => {
  const findRebaseMessage = () => wrapper.find('[data-testid="rebase-message"]');
  const findRebaseMessageText = () => findRebaseMessage().text();
  const findRebaseButton = () => wrapper.find(ActionsButton);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  [true, false].forEach((mergeRequestWidgetGraphql) => {
    describe(`widget graphql is ${mergeRequestWidgetGraphql ? 'enabled' : 'disabled'}`, () => {
      describe('while rebasing', () => {
        it('should show progress message', () => {
          createWrapper(
            {
              mr: { rebaseInProgress: true },
              service: {},
            },
            mergeRequestWidgetGraphql,
          );

          expect(findRebaseMessageText()).toContain('Rebase in progress');
        });
      });

      describe('with permissions', () => {
        const rebaseMock = jest.fn().mockResolvedValue();
        const pollMock = jest.fn().mockResolvedValue({});

        beforeEach(() => {
          createWrapper(
            {
              mr: {
                rebaseInProgress: false,
                canPushToSourceBranch: true,
              },
              service: {
                rebase: rebaseMock,
                poll: pollMock,
              },
            },
            mergeRequestWidgetGraphql,
          );
        });

        it('renders the warning message', () => {
          const text = findRebaseMessageText();

          expect(text).toContain('Merge blocked');
          expect(text.replace(/\s\s+/g, ' ')).toContain(
            'the source branch must be rebased onto the target branch',
          );
        });

        it('renders an error message when rebasing has failed', async () => {
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({ rebasingError: 'Something went wrong!' });

          await nextTick();
          expect(findRebaseMessageText()).toContain('Something went wrong!');
        });

        describe('"Rebase" button', () => {
          it('is rendered', () => {
            expect(findRebaseButton().exists()).toBe(true);
          });

          it('has rebase and rebase without CI actions', () => {
            const actionNames = findRebaseButton()
              .props('actions')
              .map((action) => action.key);

            expect(actionNames).toStrictEqual([REBASE_BUTTON_KEY, REBASE_WITHOUT_CI_BUTTON_KEY]);
          });

          it('defaults to rebase action', () => {
            expect(findRebaseButton().props('selectedKey')).toStrictEqual(REBASE_BUTTON_KEY);
          });

          it('starts the rebase when clicking', async () => {
            // ActionButtons use the actions props instead of emitting
            // a click event, therefore simulating the behavior here:
            findRebaseButton()
              .props('actions')
              .find((x) => x.key === REBASE_BUTTON_KEY)
              .handle();

            await nextTick();

            expect(rebaseMock).toHaveBeenCalledWith({ skipCi: false });
          });

          it('starts the CI-skipping rebase when clicking on "Rebase without CI"', async () => {
            // ActionButtons use the actions props instead of emitting
            // a click event, therefore simulating the behavior here:
            findRebaseButton()
              .props('actions')
              .find((x) => x.key === REBASE_WITHOUT_CI_BUTTON_KEY)
              .handle();

            await nextTick();

            expect(rebaseMock).toHaveBeenCalledWith({ skipCi: true });
          });
        });
      });

      describe('without permissions', () => {
        const exampleTargetBranch = 'fake-branch-to-test-with';

        beforeEach(() => {
          createWrapper(
            {
              mr: {
                rebaseInProgress: false,
                canPushToSourceBranch: false,
                targetBranch: exampleTargetBranch,
              },
              service: {},
            },
            mergeRequestWidgetGraphql,
          );
        });

        it('renders a message explaining user does not have permissions', () => {
          const text = findRebaseMessageText();

          expect(text).toContain(
            'Merge blocked: the source branch must be rebased onto the target branch.',
          );
          expect(text).toContain('the source branch must be rebased');
        });

        it('renders the correct target branch name', () => {
          const elem = findRebaseMessage();

          expect(elem.text()).toContain(
            `Merge blocked: the source branch must be rebased onto the target branch.`,
          );
        });

        it('does not render the "Rebase" button', () => {
          expect(findRebaseButton().exists()).toBe(false);
        });
      });

      describe('methods', () => {
        it('checkRebaseStatus', async () => {
          jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
          createWrapper(
            {
              mr: {},
              service: {
                rebase() {
                  return Promise.resolve();
                },
                poll() {
                  return Promise.resolve({
                    data: {
                      rebase_in_progress: false,
                      merge_error: null,
                    },
                  });
                },
              },
            },
            mergeRequestWidgetGraphql,
          );

          wrapper.vm.rebase();

          // Wait for the rebase request
          await nextTick();
          // Wait for the polling request
          await nextTick();
          // Wait for the eventHub to be called
          await nextTick();

          expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetRebaseSuccess');
        });
      });
    });
  });
});
