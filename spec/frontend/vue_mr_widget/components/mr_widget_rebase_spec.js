import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import WidgetRebase from '~/vue_merge_request_widget/components/states/mr_widget_rebase.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';

let wrapper;

function factory(propsData, mergeRequestWidgetGraphql) {
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
  const findRebaseMessageEl = () => wrapper.find('[data-testid="rebase-message"]');
  const findRebaseMessageElText = () => findRebaseMessageEl().text();

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  [true, false].forEach((mergeRequestWidgetGraphql) => {
    describe(`widget graphql is ${mergeRequestWidgetGraphql ? 'enabled' : 'dislabed'}`, () => {
      describe('While rebasing', () => {
        it('should show progress message', () => {
          factory(
            {
              mr: { rebaseInProgress: true },
              service: {},
            },
            mergeRequestWidgetGraphql,
          );

          expect(findRebaseMessageElText()).toContain('Rebase in progress');
        });
      });

      describe('With permissions', () => {
        it('it should render rebase button and warning message', () => {
          factory(
            {
              mr: {
                rebaseInProgress: false,
                canPushToSourceBranch: true,
              },
              service: {},
            },
            mergeRequestWidgetGraphql,
          );

          const text = findRebaseMessageElText();

          expect(text).toContain('Fast-forward merge is not possible.');
          expect(text.replace(/\s\s+/g, ' ')).toContain(
            'Rebase the source branch onto the target branch.',
          );
        });

        it('it should render error message when it fails', async () => {
          factory(
            {
              mr: {
                rebaseInProgress: false,
                canPushToSourceBranch: true,
              },
              service: {},
            },
            mergeRequestWidgetGraphql,
          );

          wrapper.setData({ rebasingError: 'Something went wrong!' });

          await nextTick();
          expect(findRebaseMessageElText()).toContain('Something went wrong!');
        });
      });

      describe('Without permissions', () => {
        it('should render a message explaining user does not have permissions', () => {
          factory(
            {
              mr: {
                rebaseInProgress: false,
                canPushToSourceBranch: false,
                targetBranch: 'foo',
              },
              service: {},
            },
            mergeRequestWidgetGraphql,
          );

          const text = findRebaseMessageElText();

          expect(text).toContain('Fast-forward merge is not possible.');
          expect(text).toContain('Rebase the source branch onto');
          expect(text).toContain('foo');
          expect(text.replace(/\s\s+/g, ' ')).toContain(
            'to allow this merge request to be merged.',
          );
        });

        it('should render the correct target branch name', () => {
          const targetBranch = 'fake-branch-to-test-with';
          factory(
            {
              mr: {
                rebaseInProgress: false,
                canPushToSourceBranch: false,
                targetBranch,
              },
              service: {},
            },
            mergeRequestWidgetGraphql,
          );

          const elem = findRebaseMessageEl();

          expect(elem.text()).toContain(
            `Fast-forward merge is not possible. Rebase the source branch onto ${targetBranch} to allow this merge request to be merged.`,
          );
        });
      });

      describe('methods', () => {
        it('checkRebaseStatus', async () => {
          jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
          factory(
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
