import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { InternalEvents } from '~/tracking';
import { createAlert } from '~/alert';
import sourceBranchRemovalMixin from '~/vue_merge_request_widget/mixins/source_branch_removal';

jest.mock('~/alert');

const TRACKING_EVENT = 'i_code_review_post_merge_delete_branch';

function createMr(overrides = {}) {
  return {
    sourceBranchRemoved: false,
    canRemoveSourceBranch: true,
    isRemovingSourceBranch: false,
    ...overrides,
  };
}

function createComponent({ mr, service } = {}) {
  return shallowMount(
    {
      template: '<div />',
      mixins: [sourceBranchRemovalMixin],
      props: ['mr'],
    },
    { propsData: { mr, service } },
  );
}

describe('sourceBranchRemovalMixin', () => {
  useMockInternalEventsTracking();
  let mr;
  let service;

  beforeEach(() => {
    mr = createMr();
    service = { removeSourceBranch: jest.fn() };
  });

  describe('shouldShowRemoveSourceBranch', () => {
    it('is true when branch exists and user can remove it', () => {
      const wrapper = createComponent({ mr, service });

      expect(wrapper.vm.shouldShowRemoveSourceBranch).toBe(true);
    });

    it('is false when sourceBranchRemoved is true', () => {
      const wrapper = createComponent({ mr: createMr({ sourceBranchRemoved: true }), service });

      expect(wrapper.vm.shouldShowRemoveSourceBranch).toBe(false);
    });

    it('is false when canRemoveSourceBranch is false', () => {
      const wrapper = createComponent({ mr: createMr({ canRemoveSourceBranch: false }), service });

      expect(wrapper.vm.shouldShowRemoveSourceBranch).toBe(false);
    });

    it('is false when isRemovingSourceBranch is true', () => {
      const wrapper = createComponent({
        mr: createMr({ isRemovingSourceBranch: true }),
        service,
      });

      expect(wrapper.vm.shouldShowRemoveSourceBranch).toBe(false);
    });
  });

  describe('removeSourceBranch', () => {
    it('tracks the given event', () => {
      service.removeSourceBranch.mockResolvedValue({ data: { message: 'Branch was deleted' } });
      const wrapper = createComponent({ mr, service });

      wrapper.vm.removeSourceBranch(TRACKING_EVENT);

      expect(InternalEvents.trackEvent).toHaveBeenCalledWith(TRACKING_EVENT);
    });

    it('calls service.removeSourceBranch', () => {
      service.removeSourceBranch.mockResolvedValue({ data: { message: 'Branch was deleted' } });
      const wrapper = createComponent({ mr, service });

      wrapper.vm.removeSourceBranch(TRACKING_EVENT);

      expect(service.removeSourceBranch).toHaveBeenCalled();
    });

    it('sets mr.sourceBranchRemoved to true on success', async () => {
      service.removeSourceBranch.mockResolvedValue({ data: { message: 'Branch was deleted' } });
      const wrapper = createComponent({ mr, service });

      wrapper.vm.removeSourceBranch(TRACKING_EVENT);
      await waitForPromises();

      expect(mr.sourceBranchRemoved).toBe(true);
    });

    it('hides the button on success', async () => {
      service.removeSourceBranch.mockResolvedValue({ data: { message: 'Branch was deleted' } });
      const wrapper = createComponent({ mr, service });

      wrapper.vm.removeSourceBranch(TRACKING_EVENT);
      await waitForPromises();

      expect(wrapper.vm.shouldShowRemoveSourceBranch).toBe(false);
    });

    it('hides the button while the request is in flight', async () => {
      service.removeSourceBranch.mockReturnValue(new Promise(() => {}));
      const wrapper = createComponent({ mr, service });

      wrapper.vm.removeSourceBranch(TRACKING_EVENT);
      await waitForPromises();

      expect(wrapper.vm.shouldShowRemoveSourceBranch).toBe(false);
    });

    it('shows an alert and restores the button on failure', async () => {
      service.removeSourceBranch.mockRejectedValue(new Error());
      const wrapper = createComponent({ mr, service });

      wrapper.vm.removeSourceBranch(TRACKING_EVENT);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong. Please try again.',
      });
      expect(wrapper.vm.shouldShowRemoveSourceBranch).toBe(true);
    });
  });
});
