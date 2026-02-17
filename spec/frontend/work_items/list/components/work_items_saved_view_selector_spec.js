import { GlDisclosureDropdown, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import WorkItemsSavedViewSelector from '~/work_items/list/components/work_items_saved_view_selector.vue';
import { CREATED_DESC } from '~/work_items/list/constants';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

jest.mock('~/lib/utils/copy_to_clipboard');
jest.mock('~/sentry/sentry_browser_wrapper');

const mockSavedView = {
  __typename: 'SavedView',
  id: 'gid://gitlab/WorkItems::SavedViews::SavedView/1',
  name: 'My View',
  userPermissions: {
    updateSavedView: true,
    deleteSavedView: true,
  },
};

describe('WorkItemsSavedViewSelector', () => {
  let wrapper;

  const createComponent = ({
    routeMock = { params: { view_id: undefined } },
    savedView = mockSavedView,
    isGroup = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemsSavedViewSelector, {
      propsData: {
        savedView,
        sortKey: CREATED_DESC,
        filters: {},
        displaySettings: {},
        fullPath: 'test-project-path',
      },
      provide: {
        isGroup,
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
  const findCopyAction = () => wrapper.findByTestId('copy-action');
  const findUnsubscribeAction = () => wrapper.findByTestId('unsubscribe-action');
  const findDeleteAction = () => wrapper.findByTestId('delete-action');
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    confirmAction.mockReset();
  });

  describe('when active', () => {
    beforeEach(() => {
      createComponent({ routeMock: { params: { view_id: '1' } } });
    });

    it('renders a dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('renders the selector and dropdown actions', () => {
      expect(findEditAction().exists()).toBe(true);
      expect(findCopyAction().exists()).toBe(true);
      expect(findUnsubscribeAction().exists()).toBe(true);
      expect(findDeleteAction().exists()).toBe(true);
    });

    it('shows the caret when active and applies appropriate styles', () => {
      expect(findSelector().classes()).toContain('saved-view-selector-active');
      expect(findSelector().props('noCaret')).toBe(false);
    });

    it('does not render edit action when user lacks update permission', () => {
      createComponent({
        routeMock: { params: { view_id: '1' } },
        savedView: {
          ...mockSavedView,
          userPermissions: {
            updateSavedView: false,
            deleteSavedView: true,
          },
        },
      });

      expect(findEditAction().exists()).toBe(false);
    });

    describe('unsubscribe action', () => {
      it('emits unsubscribe-saved-view event with saved view when clicked', async () => {
        await findUnsubscribeAction().vm.$emit('action');

        expect(wrapper.emitted('unsubscribe-saved-view')).toHaveLength(1);
        expect(wrapper.emitted('unsubscribe-saved-view')[0]).toEqual([mockSavedView]);
      });
    });

    describe('delete action', () => {
      it('renders delete action when user has delete permission', () => {
        expect(findDeleteAction().exists()).toBe(true);
      });

      it('does not render delete action when user lacks delete permission', () => {
        createComponent({
          routeMock: { params: { view_id: '1' } },
          savedView: {
            ...mockSavedView,
            userPermissions: {
              updateSavedView: true,
              deleteSavedView: false,
            },
          },
        });

        expect(findDeleteAction().exists()).toBe(false);
      });

      it('calls confirmAction with project-specific message', async () => {
        confirmAction.mockResolvedValue(false);

        await findDeleteAction().vm.$emit('action');

        expect(confirmAction).toHaveBeenCalledWith(null, {
          title: 'Are you sure you want to delete this view?',
          modalHtmlMessage:
            '<span>Deleting a view removes it from this project and from anyone who had access to it. This action cannot be undone.</span>',
          primaryBtnVariant: 'danger',
          primaryBtnText: 'Delete view',
        });
      });

      it('calls confirmAction with group-specific message', async () => {
        createComponent({
          routeMock: { params: { view_id: '1' } },
          isGroup: true,
        });
        confirmAction.mockResolvedValue(false);

        await findDeleteAction().vm.$emit('action');

        expect(confirmAction).toHaveBeenCalledWith(null, {
          title: 'Are you sure you want to delete this view?',
          modalHtmlMessage:
            '<span>Deleting a view removes it from this group and from anyone who had access to it. This action cannot be undone.</span>',
          primaryBtnVariant: 'danger',
          primaryBtnText: 'Delete view',
        });
      });

      it('emits delete-saved-view event when user confirms deletion', async () => {
        confirmAction.mockResolvedValue(true);

        findDeleteAction().vm.$emit('action');
        await waitForPromises();

        expect(wrapper.emitted('delete-saved-view')).toHaveLength(1);
        expect(wrapper.emitted('delete-saved-view')[0]).toEqual([mockSavedView]);
      });

      it('does not emit delete-saved-view event when user cancels deletion', async () => {
        confirmAction.mockResolvedValue(false);

        await findDeleteAction().vm.$emit('action');

        expect(wrapper.emitted('delete-saved-view')).toBeUndefined();
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
