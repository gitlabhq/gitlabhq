import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { setCookie } from '~/lib/utils/common_utils';
import MRMoreActionsDropdown from '~/vue_shared/components/mr_more_dropdown.vue';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  setCookie: jest.fn(),
}));

describe('MR More actions sidebar', () => {
  let wrapper;

  const findMoreDropdown = () => wrapper.findByTestId('dropdown-toggle');
  const findMoreDropdownTooltip = () => getBinding(findMoreDropdown().element, 'gl-tooltip');
  const findEditMergeRequestOption = () => wrapper.find('[data-testid="edit-merge-request"]');
  const findMarkAsReadyAndDraftOption = () =>
    wrapper.find('[data-testid="ready-and-draft-action"]');
  const findCopyReferenceButton = () => wrapper.find('[data-testid="copy-reference"]');
  const findReopenMergeRequestOption = () => wrapper.find('[data-testid="reopen-merge-request"]');
  const findReportAbuseOption = () => wrapper.find('[data-testid="report-abuse-option"]');
  const findLockMergeRequestOption = () => wrapper.find('[data-testid="lock-merge-request"]');
  const findAiOverviewToggle = () => wrapper.findByTestId('toggle-ai-overview');

  const createComponent = ({
    isCurrentUser = true,
    open = false,
    canUpdateMergeRequest = false,
    aiOverviewAvailable = false,
    aiOverviewEnabled = false,
  } = {}) => {
    wrapper = mountExtended(MRMoreActionsDropdown, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        mr: {
          iid: 1,
        },
        isCurrentUser,
        open,
        canUpdateMergeRequest,
        aiOverviewAvailable,
        aiOverviewEnabled,
      },
    });
  };

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

    it('should not have the ready and draft option when the MR is open and `canUpdateMergeRequest` is false', () => {
      createComponent({
        open: true,
        canUpdateMergeRequest: false,
      });

      expect(findMarkAsReadyAndDraftOption().exists()).toBe(false);
    });

    it('should have the ready and draft option when the MR is open and `canUpdateMergeRequest` is true', () => {
      createComponent({
        open: true,
        canUpdateMergeRequest: true,
      });

      expect(findMarkAsReadyAndDraftOption().exists()).toBe(true);
    });

    it('should have the reopen option when the MR is closed and `canUpdateMergeRequest` is true', () => {
      createComponent({
        open: false,
        canUpdateMergeRequest: true,
      });

      expect(findReopenMergeRequestOption().exists()).toBe(true);
    });

    it('should not have the reopen option when the MR is closed and `canUpdateMergeRequest` is false', () => {
      createComponent({
        open: false,
        canUpdateMergeRequest: false,
      });

      expect(findReopenMergeRequestOption().exists()).toBe(false);
    });
  });

  describe('Lock merge request', () => {
    it.each`
      copy            | canUpdateMergeRequest | expected
      ${'should'}     | ${true}               | ${true}
      ${'should not'} | ${false}              | ${false}
    `(
      '$copy have the lock option when `canUpdateMergeRequest` is $canUpdateMergeRequest',
      ({ canUpdateMergeRequest, expected }) => {
        createComponent({
          canUpdateMergeRequest,
        });
        expect(findLockMergeRequestOption().exists()).toBe(expected);
      },
    );
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

  describe('AI overview toggle', () => {
    useMockLocationHelper();

    it('is hidden when the AI overview is not available', () => {
      createComponent();

      expect(findAiOverviewToggle().exists()).toBe(false);
    });

    it('offers to opt in when the AI overview is available but not enabled', () => {
      createComponent({ aiOverviewAvailable: true });

      expect(findAiOverviewToggle().text()).toBe('Try the new overview');
    });

    it('offers to opt out when the AI overview is enabled', () => {
      createComponent({ aiOverviewAvailable: true, aiOverviewEnabled: true });

      expect(findAiOverviewToggle().text()).toBe('Switch to the classic overview');
    });

    it.each`
      aiOverviewEnabled | cookieValue
      ${false}          | ${'true'}
      ${true}           | ${'false'}
    `(
      'writes $cookieValue and reloads when enabled is $aiOverviewEnabled',
      ({ aiOverviewEnabled, cookieValue }) => {
        createComponent({ aiOverviewAvailable: true, aiOverviewEnabled });

        findAiOverviewToggle().find('button').trigger('click');

        expect(setCookie).toHaveBeenCalledWith('mr_ai_overview_enabled', cookieValue);
        expect(window.location.reload).toHaveBeenCalled();
      },
    );
  });

  describe('More actions menu', () => {
    createComponent();

    it('renders the dropdown button', () => {
      createComponent();

      expect(findMoreDropdown().exists()).toBe(true);
    });

    it('renders tooltip', () => {
      createComponent();

      expect(findMoreDropdownTooltip().value).toBe('Merge request actions');
    });
  });
});
