import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import WidgetRebase from '~/vue_merge_request_widget/components/states/mr_widget_rebase.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

let wrapper;

function createWrapper(propsData) {
  wrapper = mount(WidgetRebase, {
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
  const findStandardRebaseButton = () => wrapper.find('[data-testid="standard-rebase-button"]');
  const findRebaseWithoutCiButton = () => wrapper.find('[data-testid="rebase-without-ci-button"]');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });
  describe('while rebasing', () => {
    it('should show progress message', () => {
      createWrapper({
        mr: { rebaseInProgress: true },
        service: {},
      });

      expect(findRebaseMessageText()).toContain('Rebase in progress');
    });
  });

  describe('with permissions', () => {
    const rebaseMock = jest.fn().mockResolvedValue();
    const pollMock = jest.fn().mockResolvedValue({});

    it('renders the warning message', () => {
      createWrapper({
        mr: {
          rebaseInProgress: false,
          canPushToSourceBranch: true,
        },
        service: {
          rebase: rebaseMock,
          poll: pollMock,
        },
      });

      const text = findRebaseMessageText();

      expect(text).toContain('Merge blocked');
      expect(text.replace(/\s\s+/g, ' ')).toContain(
        'the source branch must be rebased onto the target branch',
      );
    });

    it('renders an error message when rebasing has failed', async () => {
      createWrapper({
        mr: {
          rebaseInProgress: false,
          canPushToSourceBranch: true,
        },
        service: {
          rebase: rebaseMock,
          poll: pollMock,
        },
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ rebasingError: 'Something went wrong!' });

      await nextTick();
      expect(findRebaseMessageText()).toContain('Something went wrong!');
    });

    describe('Rebase buttons', () => {
      beforeEach(() => {
        createWrapper({
          mr: {
            rebaseInProgress: false,
            canPushToSourceBranch: true,
          },
          service: {
            rebase: rebaseMock,
            poll: pollMock,
          },
        });
      });

      it('renders both buttons', () => {
        expect(findRebaseWithoutCiButton().exists()).toBe(true);
        expect(findStandardRebaseButton().exists()).toBe(true);
      });

      it('starts the rebase when clicking', async () => {
        findStandardRebaseButton().vm.$emit('click');

        await nextTick();

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: false });
      });

      it('starts the CI-skipping rebase when clicking on "Rebase without CI"', async () => {
        findRebaseWithoutCiButton().vm.$emit('click');

        await nextTick();

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: true });
      });
    });

    describe('Rebase when pipelines must succeed is enabled', () => {
      beforeEach(() => {
        createWrapper({
          mr: {
            rebaseInProgress: false,
            canPushToSourceBranch: true,
            onlyAllowMergeIfPipelineSucceeds: true,
          },
          service: {
            rebase: rebaseMock,
            poll: pollMock,
          },
        });
      });

      it('renders only the rebase button', () => {
        expect(findRebaseWithoutCiButton().exists()).toBe(false);
        expect(findStandardRebaseButton().exists()).toBe(true);
      });

      it('starts the rebase when clicking', async () => {
        findStandardRebaseButton().vm.$emit('click');

        await nextTick();

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: false });
      });
    });

    describe('Rebase when pipelines must succeed and skipped pipelines are considered successful are enabled', () => {
      beforeEach(() => {
        createWrapper({
          mr: {
            rebaseInProgress: false,
            canPushToSourceBranch: true,
            onlyAllowMergeIfPipelineSucceeds: true,
            allowMergeOnSkippedPipeline: true,
          },
          service: {
            rebase: rebaseMock,
            poll: pollMock,
          },
        });
      });

      it('renders both rebase buttons', () => {
        expect(findRebaseWithoutCiButton().exists()).toBe(true);
        expect(findStandardRebaseButton().exists()).toBe(true);
      });

      it('starts the rebase when clicking', async () => {
        findStandardRebaseButton().vm.$emit('click');

        await nextTick();

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: false });
      });

      it('starts the CI-skipping rebase when clicking on "Rebase without CI"', async () => {
        findRebaseWithoutCiButton().vm.$emit('click');

        await nextTick();

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: true });
      });
    });
  });

  describe('without permissions', () => {
    const exampleTargetBranch = 'fake-branch-to-test-with';

    describe('UI text', () => {
      beforeEach(() => {
        createWrapper({
          mr: {
            rebaseInProgress: false,
            canPushToSourceBranch: false,
            targetBranch: exampleTargetBranch,
          },
          service: {},
        });
      });

      it('renders a message explaining user does not have permissions', () => {
        const text = findRebaseMessageText();

        expect(text).toContain('Merge blocked:');
        expect(text).toContain('the source branch must be rebased');
      });

      it('renders the correct target branch name', () => {
        const text = findRebaseMessageText();

        expect(text).toContain('Merge blocked:');
        expect(text).toContain('the source branch must be rebased onto the target branch.');
      });
    });

    it('does render the "Rebase without pipeline" button', () => {
      createWrapper({
        mr: {
          rebaseInProgress: false,
          canPushToSourceBranch: false,
          targetBranch: exampleTargetBranch,
        },
        service: {},
      });

      expect(findRebaseWithoutCiButton().exists()).toBe(true);
    });
  });

  describe('methods', () => {
    it('checkRebaseStatus', async () => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
      createWrapper({
        mr: {},
        service: {
          rebase() {
            return Promise.resolve();
          },
          poll() {
            return Promise.resolve({
              data: {
                rebase_in_progress: false,
                should_be_rebased: false,
                merge_error: null,
              },
            });
          },
        },
      });

      wrapper.vm.rebase();

      // Wait for the rebase request
      await nextTick();
      // Wait for the polling request
      await nextTick();
      // Wait for the eventHub to be called
      await nextTick();

      expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetRebaseSuccess');
      expect(toast).toHaveBeenCalledWith('Rebase completed');
    });
  });
});
