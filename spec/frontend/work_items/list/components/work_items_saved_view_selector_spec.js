import { GlDisclosureDropdown, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import WorkItemsSavedViewSelector from '~/work_items/list/components/work_items_saved_view_selector.vue';
import { CREATED_DESC } from '~/work_items/list/constants';

jest.mock('~/lib/utils/copy_to_clipboard');
jest.mock('~/sentry/sentry_browser_wrapper');

const mockSavedView = {
  __typename: 'SavedView',
  id: 'gid://gitlab/WorkItems::SavedViews::SavedView/1',
  name: 'My View',
  userPermissions: {
    updateSavedView: true,
  },
};

describe('WorkItemsSavedViewSelector', () => {
  let wrapper;

  const createComponent = ({
    routeMock = { params: { view_id: undefined } },
    savedView = mockSavedView,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemsSavedViewSelector, {
      propsData: {
        savedView,
        savedSort: CREATED_DESC,
      },
      mocks: {
        $route: routeMock,
        $toast: {
          show: jest.fn(),
        },
      },
    });
  };

  const findSelector = () => wrapper.findByTestId('saved-view-selector');
  const findEditAction = () => wrapper.findByTestId('edit-action');
  const findDuplicateAction = () => wrapper.findByTestId('duplicate-action');
  const findCopyAction = () => wrapper.findByTestId('copy-action');
  const findUnsubscribeAction = () => wrapper.findByTestId('unsubscribe-action');
  const findDeleteAction = () => wrapper.findByTestId('delete-action');
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findButton = () => wrapper.findComponent(GlButton);

  describe('when active', () => {
    beforeEach(() => {
      createComponent({ routeMock: { params: { view_id: '1' } } });
    });

    it('renders a dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('renders the selector and dropdown actions', () => {
      expect(findEditAction().exists()).toBe(true);
      expect(findDuplicateAction().exists()).toBe(true);
      expect(findCopyAction().exists()).toBe(true);
      expect(findUnsubscribeAction().exists()).toBe(true);
      expect(findDeleteAction().exists()).toBe(true);
    });

    it('shows the caret when active and applies appropriate styles', () => {
      expect(findSelector().classes()).toContain('saved-view-selector-active');
      expect(findSelector().props('noCaret')).toBe(false);
    });

    it('does not render edit action when there is no permission', () => {
      createComponent({
        routeMock: { params: { view_id: '1' } },
        savedView: {
          ...mockSavedView,
          userPermissions: {
            updateSavedView: false,
          },
        },
      });

      expect(findEditAction().exists()).toBe(false);
    });

    describe('unsubscribe action', () => {
      it('emits remove-saved-view event with saved view when clicked', async () => {
        await findUnsubscribeAction().vm.$emit('action');

        expect(wrapper.emitted('remove-saved-view')).toHaveLength(1);
        expect(wrapper.emitted('remove-saved-view')[0]).toEqual([mockSavedView]);
      });
    });
  });

  describe('when not active', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a button as a link with correct value', () => {
      const button = findButton();
      expect(button.exists()).toBe(true);
      expect(button.props('to')).toEqual({ name: 'savedView', params: { view_id: '1' } });
    });
  });

  describe('copy view link', () => {
    const mockLocationHref = 'http://127.0.0.1:3000/groups/gitlab-org/-/work_items/views/1';

    beforeEach(() => {
      copyToClipboard.mockReset();
      Sentry.captureException.mockReset();
      Object.defineProperty(window, 'location', {
        value: { href: mockLocationHref },
        writable: true,
      });
    });

    it('copies current URL to clipboard and shows toast on success', async () => {
      createComponent({ routeMock: { params: { view_id: '1' } } });
      copyToClipboard.mockResolvedValue();

      findCopyAction().vm.$emit('action');
      await waitForPromises();

      expect(copyToClipboard).toHaveBeenCalledWith(mockLocationHref);
      expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Link to view copied to clipboard.');
    });

    it('captures exception when copy fails', async () => {
      createComponent({ routeMock: { params: { view_id: '1' } } });
      const error = new Error('Copy failed');
      copyToClipboard.mockRejectedValue(error);

      findCopyAction().vm.$emit('action');
      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });
});
