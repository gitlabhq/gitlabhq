import { shallowMount } from '@vue/test-utils';
import MRMoreActionsDropdown from '~/vue_shared/components/mr_more_dropdown.vue';

describe('MR More actions sidebar', () => {
  let wrapper;

  const findNotificationToggle = () => wrapper.find('[data-testid="notification-toggle"]');
  const findEditMergeRequestOption = () => wrapper.find('[data-testid="edit-merge-request"]');
  const findMarkAsReadyAndDraftOption = () =>
    wrapper.find('[data-testid="ready-and-draft-action"]');
  const findCopyReferenceButton = () => wrapper.find('[data-testid="copy-reference"]');
  const findReopenMergeRequestOption = () => wrapper.find('[data-testid="reopen-merge-request"]');
  const findReportAbuseOption = () => wrapper.find('[data-testid="report-abuse-option"]');

  const createComponent = ({
    isCurrentUser = true,
    isLoggedIn = true,
    open = false,
    canUpdateMergeRequest = false,
  } = {}) => {
    wrapper = shallowMount(MRMoreActionsDropdown, {
      propsData: {
        mr: {
          iid: 1,
        },
        isCurrentUser,
        isLoggedIn,
        open,
        canUpdateMergeRequest,
      },
    });
  };

  describe('Notifications toggle', () => {
    it.each`
      isLoggedIn | showNotificationToggle
      ${false}   | ${false}
      ${true}    | ${true}
    `("when is isLoggedIn as '$isLoggedIn'", ({ isLoggedIn, showNotificationToggle }) => {
      createComponent({
        isLoggedIn,
      });

      expect(findNotificationToggle().exists()).toBe(showNotificationToggle);
    });
  });

  describe('Edit/Draft/Reopen MR', () => {
    it('should not have the edit option when `canUpdateMergeRequest` is false', () => {
      createComponent();

      expect(findEditMergeRequestOption().exists()).toBe(false);
    });

    it('should have the edit option when `canUpdateMergeRequest` is true', () => {
      createComponent({
        canUpdateMergeRequest: true,
      });

      expect(findEditMergeRequestOption().exists()).toBe(true);
    });

    it('should not have the ready and draft option when the the MR is open and `canUpdateMergeRequest` is false', () => {
      createComponent({
        open: true,
        canUpdateMergeRequest: false,
      });

      expect(findMarkAsReadyAndDraftOption().exists()).toBe(false);
    });

    it('should have the ready and draft option when the the MR is open and `canUpdateMergeRequest` is true', () => {
      createComponent({
        open: true,
        canUpdateMergeRequest: true,
      });

      expect(findMarkAsReadyAndDraftOption().exists()).toBe(true);
    });

    it('should have the reopen option when the the MR is closed and `canUpdateMergeRequest` is true', () => {
      createComponent({
        open: false,
        canUpdateMergeRequest: true,
      });

      expect(findReopenMergeRequestOption().exists()).toBe(true);
    });

    it('should not have the reopen option when the the MR is closed and `canUpdateMergeRequest` is false', () => {
      createComponent({
        open: false,
        canUpdateMergeRequest: false,
      });

      expect(findReopenMergeRequestOption().exists()).toBe(false);
    });
  });

  describe('Copy reference', () => {
    it('should be visible', () => {
      createComponent();

      expect(findCopyReferenceButton().exists()).toBe(true);
    });
  });

  describe('Report abuse action', () => {
    it('should not have the option by default', () => {
      createComponent();

      expect(findReportAbuseOption().exists()).toBe(false);
    });

    it('should have the option when not the current user', () => {
      createComponent({ isCurrentUser: false });

      expect(findReportAbuseOption().exists()).toBe(true);
    });
  });
});
