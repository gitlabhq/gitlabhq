import { GlDisclosureDropdownItem, GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsCreateSavedViewDropdown from '~/work_items/list/components/work_items_create_saved_view_dropdown.vue';
import WorkItemsNewSavedViewModal from '~/work_items/list/components/work_items_new_saved_view_modal.vue';
import WorkItemsExistingSavedViewsModal from '~/work_items/list/components/work_items_existing_saved_views_modal.vue';
import { CREATED_DESC } from '~/work_items/list/constants';

describe('WorkItemsCreateSavedViewDropdown', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemsCreateSavedViewDropdown, {
      propsData: {
        fullPath: 'test-project-path',
        sortKey: CREATED_DESC,
        filters: {},
        displaySettings: {},
        ...props,
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

  beforeEach(() => {
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
    });

    it('passes showSubscriptionLimitWarning to child modals', () => {
      createComponent({ props: { showSubscriptionLimitWarning: true } });

      expect(findNewSavedViewModal().props('showSubscriptionLimitWarning')).toBe(true);
      expect(findExistingSavedViewsModal().props('showSubscriptionLimitWarning')).toBe(true);
    });
  });
});
