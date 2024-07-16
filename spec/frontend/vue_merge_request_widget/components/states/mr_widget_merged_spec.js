import { getAllByRole } from '@testing-library/dom';
import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import { OPEN_REVERT_MODAL, OPEN_CHERRY_PICK_MODAL } from '~/projects/commit/constants';
import modalEventHub from '~/projects/commit/event_hub';
import MergedComponent from '~/vue_merge_request_widget/components/states/mr_widget_merged.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';

describe('MRWidgetMerged', () => {
  let wrapper;
  const targetBranch = 'foo';
  const mr = {
    isRemovingSourceBranch: false,
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

  const createComponent = (customMrFields = {}) => {
    wrapper = mount(MergedComponent, {
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
    jest.spyOn(document, 'dispatchEvent');
    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
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

    it('is not displayed when canRemoveSourceBranch is true', () => {
      createComponent({ sourceBranchRemoved: false, canRemoveSourceBranch: false });

      expect(findRemoveSourceBranchButton()).toBe(undefined);
    });

    it('is not displayed when is making request', async () => {
      createComponent({ sourceBranchRemoved: false, canRemoveSourceBranch: true });

      await findRemoveSourceBranchButton().trigger('click');

      expect(findRemoveSourceBranchButton()).toBe(undefined);
    });

    it('is not displayed when all are true', () => {
      createComponent({
        isRemovingSourceBranch: true,
        sourceBranchRemoved: false,
        canRemoveSourceBranch: true,
      });

      expect(findRemoveSourceBranchButton()).toBe(undefined);
    });
  });

  it('should set flag and call service then request main component to update the widget when branch is removed', async () => {
    createComponent({ sourceBranchRemoved: false });
    jest.spyOn(service, 'removeSourceBranch').mockResolvedValue({
      data: {
        message: 'Branch was deleted',
      },
    });

    await findRemoveSourceBranchButton().trigger('click');

    await waitForPromises();

    const args = eventHub.$emit.mock.calls[0];

    expect(args[0]).toEqual('MRWidgetUpdateRequested');
    expect(args[1]).not.toThrow();
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
});
