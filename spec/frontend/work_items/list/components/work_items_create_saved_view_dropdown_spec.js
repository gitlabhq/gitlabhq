import { GlDisclosureDropdownItem, GlIcon, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsCreateSavedViewDropdown from '~/work_items/list/components/work_items_create_saved_view_dropdown.vue';
import WorkItemsNewSavedViewModal from '~/work_items/list/components/work_items_new_saved_view_modal.vue';
import WorkItemsExistingSavedViewsModal from '~/work_items/list/components/work_items_existing_saved_views_modal.vue';
import { CREATED_DESC } from '~/work_items/list/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/url_utility');

describe('WorkItemsCreateSavedViewDropdown', () => {
  let wrapper;

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemsCreateSavedViewDropdown, {
      propsData: {
        fullPath: 'test-project-path',
        sortKey: CREATED_DESC,
        filters: {},
        displaySettings: {},
        ...props,
      },
      provide: {
        canCreateSavedView: true,
        signInPath: 'sign-in-path',
        ...provide,
      },
    });
  };

  const findDropdownToggle = () => wrapper.findByTestId('add-saved-view-toggle');
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findNewSavedViewModal = () => wrapper.findComponent(WorkItemsNewSavedViewModal);
  const findExistingSavedViewsModal = () => wrapper.findComponent(WorkItemsExistingSavedViewsModal);
  const findWarningMessage = () => wrapper.find('.gl-bg-orange-50');
  const findWarningIcon = () => wrapper.findComponent(GlIcon);
  const findLearnMoreLink = () => wrapper.findComponent(GlLink);
  const findAddViewButton = () => wrapper.findByTestId('add-saved-view-fallback');

  describe('when user is logged in and can create saved views', () => {
    beforeEach(() => {
      isLoggedIn.mockReturnValue(true);
      createComponent();
    });

    it('renders the dropdown toggle', () => {
      expect(findDropdownToggle().exists()).toBe(true);
      expect(findDropdownToggle().props('toggleText')).toBe('Add view');
    });

    it('renders dropdown items', () => {
      expect(findDropdownItems()).toHaveLength(2);
    });

    describe('New view option', () => {
      it('opens the new saved view modal when clicked', async () => {
        expect(findNewSavedViewModal().props('show')).toBe(false);

        await findDropdownItems().at(0).vm.$emit('action');

        expect(findNewSavedViewModal().props('show')).toBe(true);
      });

      it('passes correct props to new saved view modal', () => {
        expect(findNewSavedViewModal().props()).toMatchObject({
          fullPath: 'test-project-path',
          sortKey: CREATED_DESC,
          showSubscriptionLimitWarning: false,
        });
      });
    });

    describe('Browse views option', () => {
      it('opens the existing saved views modal when clicked', async () => {
        expect(findExistingSavedViewsModal().props('show')).toBe(false);

        await findDropdownItems().at(1).vm.$emit('action');

        expect(findExistingSavedViewsModal().props('show')).toBe(true);
      });

      it('passes correct props to existing saved views modal', () => {
        expect(findExistingSavedViewsModal().props()).toMatchObject({
          fullPath: 'test-project-path',
          showSubscriptionLimitWarning: false,
        });
      });
    });

    describe('subscription limit warning', () => {
      it('does not show warning when showSubscriptionLimitWarning is false', () => {
        createComponent({ props: { showSubscriptionLimitWarning: false } });

        expect(findWarningMessage().exists()).toBe(false);
      });

      it('shows warning when showSubscriptionLimitWarning is true', () => {
        createComponent({ props: { showSubscriptionLimitWarning: true } });

        expect(findWarningMessage().exists()).toBe(true);
        expect(findWarningIcon().props('name')).toBe('warning');
        expect(findLearnMoreLink().exists()).toBe(true);
        expect(findLearnMoreLink().attributes('href')).toBe(
          helpPagePath('user/work_items/saved_views.md', { anchor: 'saved-view-limits' }),
        );
      });

      it('passes showSubscriptionLimitWarning to child modals', () => {
        createComponent({ props: { showSubscriptionLimitWarning: true } });

        expect(findNewSavedViewModal().props('showSubscriptionLimitWarning')).toBe(true);
        expect(findExistingSavedViewsModal().props('showSubscriptionLimitWarning')).toBe(true);
      });
    });
  });

  describe('when user cannot create saved views', () => {
    describe('when logged in', () => {
      beforeEach(() => {
        isLoggedIn.mockReturnValue(true);
        createComponent({ provide: { canCreateSavedView: false } });
      });

      it('renders fallback button instead of dropdown', () => {
        expect(findDropdownToggle().exists()).toBe(false);
        expect(findAddViewButton().exists()).toBe(true);
        expect(findAddViewButton().text()).toBe('Add view');
      });

      it('opens existing views modal when clicked', async () => {
        expect(findExistingSavedViewsModal().props('show')).toBe(false);

        await findAddViewButton().vm.$emit('click');

        expect(findExistingSavedViewsModal().props('show')).toBe(true);
      });
    });

    describe('when logged out', () => {
      beforeEach(async () => {
        isLoggedIn.mockReturnValue(false);
        createComponent({ provide: { canCreateSavedView: false } });
        await nextTick();
      });

      it('redirects to sign-in when fallback button clicked', async () => {
        await findAddViewButton().vm.$emit('click');

        expect(visitUrl).toHaveBeenCalledWith('sign-in-path');
      });
    });
  });
});
