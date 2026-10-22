import { getAllByRole } from '@testing-library/dom';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import { OPEN_REVERT_MODAL, OPEN_CHERRY_PICK_MODAL } from '~/projects/commit/constants';
import modalEventHub from '~/projects/commit/event_hub';
import MergedComponent from '~/vue_merge_request_widget/components/states/mr_widget_merged.vue';
import mergeSourceQuery from '~/vue_merge_request_widget/queries/states/merge_source.query.graphql';

Vue.use(VueApollo);

describe('MRWidgetMerged', () => {
  let wrapper;
  const targetBranch = 'foo';
  const mr = {
    cherryPickInForkPath: false,
    canCherryPickInCurrentMR: true,
    revertInForkPath: false,
    canRevertInCurrentMR: true,
    canRemoveSourceBranch: true,
    sourceBranchRemoved: true,
    metrics: {
      mergedBy: {
        name: 'Administrator',
        username: 'root',
        webUrl: 'http://localhost:3000/root',
        avatarUrl:
          'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      },
      mergedAt: 'Jan 24, 2018 1:02pm UTC',
      readableMergedAt: '',
      closedBy: {},
      closedAt: 'Jan 24, 2018 1:02pm UTC',
      readableClosedAt: '',
    },
    updatedAt: 'mergedUpdatedAt',
    shortMergeCommitSha: '958c0475',
    mergeCommitSha: '958c047516e182dfc52317f721f696e8a1ee85ed',
    mergeCommitPath:
      'http://localhost:3000/root/nautilus/commit/f7ce827c314c9340b075657fd61c789fb01cf74d',
    sourceBranch: 'bar',
    targetBranch,
  };

  // Stubbing requestAnimationFrame because GlDisclosureDropdown uses it to delay its `action` event.
  useFakeRequestAnimationFrame();

  const service = {
    removeSourceBranch: () => nextTick(),
  };

  const mergeSourceResponse = (mergeSource) => ({
    data: {
      project: {
        id: 'gid://gitlab/Project/1',
        mergeRequest: { id: 'gid://gitlab/MergeRequest/1', mergeSource },
      },
    },
  });

  let mergeSourceHandler;

  const createComponent = (customMrFields = {}, { glFeatures = {} } = {}) => {
    wrapper = mount(MergedComponent, {
      apolloProvider: createMockApollo([[mergeSourceQuery, mergeSourceHandler]]),
      provide: { glFeatures },
      propsData: {
        mr: {
          ...mr,
          ...customMrFields,
        },
        service,
      },
    });
  };

  beforeEach(() => {
    mergeSourceHandler = jest.fn().mockResolvedValue(mergeSourceResponse(null));
  });

  beforeEach(() => {
    jest.spyOn(document, 'dispatchEvent');
  });

  const findButtonByText = (text) =>
    wrapper.findAll('button').wrappers.find((w) => w.text() === text);
  const findRemoveSourceBranchButton = () => findButtonByText('Delete source branch');

  describe('remove source branch button', () => {
    it('is displayed when sourceBranchRemoved is false', () => {
      createComponent({ sourceBranchRemoved: false });

      expect(findRemoveSourceBranchButton().exists()).toBe(true);
    });

    it('is not displayed when sourceBranchRemoved is true', () => {
      createComponent({ sourceBranchRemoved: true });

      expect(findRemoveSourceBranchButton()).toBe(undefined);
    });

    it('is not displayed when canRemoveSourceBranch is false', () => {
      createComponent({ sourceBranchRemoved: false, canRemoveSourceBranch: false });

      expect(findRemoveSourceBranchButton()).toBe(undefined);
    });

    it('is not displayed when is making request', async () => {
      createComponent({ sourceBranchRemoved: false, canRemoveSourceBranch: true });

      await findRemoveSourceBranchButton().trigger('click');

      expect(findRemoveSourceBranchButton()).toBe(undefined);
    });
  });

  it('should remove the button when branch is successfully deleted', async () => {
    createComponent({ sourceBranchRemoved: false });
    jest.spyOn(service, 'removeSourceBranch').mockResolvedValue({
      data: {
        message: 'Branch was deleted',
      },
    });

    await findRemoveSourceBranchButton().trigger('click');

    await waitForPromises();

    expect(findRemoveSourceBranchButton()).toBe(undefined);
  });

  it('calls dispatchDocumentEvent to load in the modal component', () => {
    createComponent();

    expect(document.dispatchEvent).toHaveBeenCalledWith(new CustomEvent('merged:UpdateActions'));
  });

  it('emits event to open the revert modal on revert button click', () => {
    createComponent();
    const eventHubSpy = jest.spyOn(modalEventHub, '$emit');

    getAllByRole(wrapper.element, 'button', { name: /Revert/i })[0].click();

    expect(eventHubSpy).toHaveBeenCalledWith(OPEN_REVERT_MODAL);
  });

  it('emits event to open the cherry-pick modal on cherry-pick button click', () => {
    createComponent();
    const eventHubSpy = jest.spyOn(modalEventHub, '$emit');

    getAllByRole(wrapper.element, 'button', { name: /Cherry-pick/i })[0].click();

    expect(eventHubSpy).toHaveBeenCalledWith(OPEN_CHERRY_PICK_MODAL);
  });

  it('has merged by information', () => {
    createComponent();

    expect(wrapper.text()).toContain('Merged by');
    expect(wrapper.text()).toContain('Administrator');
  });

  it('shows revert and cherry-pick buttons', () => {
    createComponent();

    expect(wrapper.text()).toContain('Revert');
    expect(wrapper.text()).toContain('Cherry-pick');
  });

  it('should use mergedEvent mergedAt as tooltip title', () => {
    createComponent();

    expect(wrapper.find('time').attributes('title')).toBe('Jan 24, 2018 1:02pm UTC');
  });

  describe('merge source', () => {
    const findMergeSource = () => wrapper.find('[data-testid="merge-source"]');
    const mrFields = { targetProjectFullPath: 'root/nautilus', iid: 2 };
    const withFlag = { glFeatures: { mergeRequestWidgetMergeSource: true } };

    it('does not query the merge source when the feature flag is disabled', async () => {
      createComponent(mrFields);
      await waitForPromises();

      expect(mergeSourceHandler).not.toHaveBeenCalled();
      expect(findMergeSource().exists()).toBe(false);
    });

    it('shows nothing when the merge request was merged in GitLab', async () => {
      createComponent(mrFields, withFlag);
      await waitForPromises();

      expect(mergeSourceHandler).toHaveBeenCalledWith({ projectPath: 'root/nautilus', iid: '2' });
      expect(findMergeSource().exists()).toBe(false);
    });

    it('links the merge request it was merged through', async () => {
      mergeSourceHandler.mockResolvedValue(
        mergeSourceResponse({
          commitSha: null,
          mergeRequest: {
            id: 'gid://gitlab/MergeRequest/3',
            reference: '!3',
            webPath: '/root/nautilus/-/merge_requests/3',
          },
        }),
      );
      createComponent(mrFields, withFlag);
      await waitForPromises();

      expect(findMergeSource().text()).toBe('Commits included in !3');
      expect(findMergeSource().find('a').attributes('href')).toBe(
        '/root/nautilus/-/merge_requests/3',
      );
    });

    it('shows the pushed commit', async () => {
      mergeSourceHandler.mockResolvedValue(
        mergeSourceResponse({
          commitSha: '8dd2c02193982581ca65aafd829ece9c6084c523',
          mergeRequest: null,
        }),
      );
      createComponent(mrFields, withFlag);
      await waitForPromises();

      expect(findMergeSource().text()).toBe('Commits included in a direct push to foo (8dd2c021)');
    });

    it('does not link a merge request the user cannot read', async () => {
      mergeSourceHandler.mockResolvedValue(
        mergeSourceResponse({ commitSha: null, mergeRequest: null }),
      );
      createComponent(mrFields, withFlag);
      await waitForPromises();

      expect(findMergeSource().text()).toBe(
        "Commits included in a merge request that you don't have access to",
      );
      expect(findMergeSource().find('a').exists()).toBe(false);
    });
  });
});
