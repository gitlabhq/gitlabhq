import { nextTick } from 'vue';
import { GlDisclosureDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import {
  WORK_ITEMS_TYPE_MAP,
  WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
} from '~/work_items/constants';
import CreateWorkItemCancelConfirmationModal from '~/work_items/components/create_work_item_cancel_confirmation_modal.vue';

const showToast = jest.fn();

describe('CreateWorkItemModal', () => {
  let wrapper;

  const findTrigger = () => wrapper.find('[data-testid="new-epic-button"]');
  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findCreateModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(CreateWorkItem);
  const findOpenInFullPageButton = () => wrapper.find('[data-testid="new-work-item-modal-link"]');
  const findCancelConfirmationModal = () =>
    wrapper.findComponent(CreateWorkItemCancelConfirmationModal);

  const createComponent = ({
    asDropdownItem = false,
    hideButton = false,
    workItemTypeName = 'EPIC',
    relatedItem = null,
    alwaysShowWorkItemTypeSelect = false,
  } = {}) => {
    wrapper = shallowMount(CreateWorkItemModal, {
      propsData: {
        workItemTypeName,
        asDropdownItem,
        hideButton,
        relatedItem,
        alwaysShowWorkItemTypeSelect,
      },
      provide: {
        fullPath: 'full-path',
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
      stubs: {
        GlModal,
      },
    });
  };

  it('shows toast on workItemCreated', async () => {
    createComponent();

    await waitForPromises();
    findForm().vm.$emit('workItemCreated', { webUrl: '/' });

    expect(showToast).toHaveBeenCalledWith('Epic created', expect.any(Object));
  });

  describe('default trigger', () => {
    it('opens modal and prevents following link on click', async () => {
      createComponent();

      await waitForPromises();

      const mockEvent = { preventDefault: jest.fn() };
      findTrigger().vm.$emit('click', mockEvent);

      await nextTick();

      expect(findCreateModal().props('visible')).toBe(true);
      expect(mockEvent.preventDefault).toHaveBeenCalled();
    });

    it('does not open modal or prevent link default on ctrl+click', async () => {
      createComponent();

      await waitForPromises();

      const mockEvent = { preventDefault: jest.fn(), ctrlKey: true };
      findTrigger().vm.$emit('click', mockEvent);

      await nextTick();

      expect(findCreateModal().props('visible')).toBe(false);
      expect(mockEvent.preventDefault).not.toHaveBeenCalled();
    });

    it('does not render when hideButton=true', () => {
      createComponent({ hideButton: true });

      expect(findTrigger().exists()).toBe(false);
    });

    it('has text of "New item" when the `alwaysShowWorkItemTypeSelect` prop is `true` and we also have a `workItemTypeName`', () => {
      createComponent({ alwaysShowWorkItemTypeSelect: true, workItemTypeName: 'ISSUE' });

      expect(findTrigger().text()).toBe('New item');
    });
  });

  describe('dropdown item trigger', () => {
    it('renders a dropdown item component', () => {
      createComponent({ asDropdownItem: true });

      expect(findDropdownItem().exists()).toBe(true);
    });
  });

  it('opens modal when visible prop updates to true', async () => {
    createComponent();

    expect(findCreateModal().props('visible')).toBe(false);

    await wrapper.setProps({ visible: true });

    expect(findCreateModal().props('visible')).toBe(true);
  });

  it('closes modal on cancel event from form', async () => {
    createComponent();

    await waitForPromises();

    await nextTick();

    findForm().vm.$emit('cancel');

    expect(findCreateModal().props('visible')).toBe(false);
  });

  for (const [workItemTypeName, vals] of Object.entries(WORK_ITEMS_TYPE_MAP)) {
    it(`has link to new work item page in modal header for ${workItemTypeName}`, async () => {
      createComponent({ workItemTypeName });

      const routeParamName = vals.routeParamName || WORK_ITEM_TYPE_ROUTE_WORK_ITEM;

      await waitForPromises();

      expect(findOpenInFullPageButton().attributes().href).toBe(
        `/full-path/-/${routeParamName}/new`,
      );
    });
  }

  describe('when there is a related item', () => {
    beforeEach(async () => {
      createComponent({
        relatedItem: { id: 'gid://gitlab/WorkItem/843', type: 'Epic', reference: 'flightjs#53' },
      });
      await waitForPromises();
      await nextTick();
    });

    it('appends the related item id to the full page button href', () => {
      expect(findOpenInFullPageButton().attributes('href')).toBe(
        '/full-path/-/epics/new?related_item_id=gid://gitlab/WorkItem/843',
      );
    });
  });

  describe('when "changeType" event is emitted', () => {
    it('updates the selected type', async () => {
      createComponent();

      expect(wrapper.find('h2').text()).toBe('New epic');

      findForm().vm.$emit('changeType', WORK_ITEM_TYPE_ENUM_KEY_RESULT);
      await nextTick();
      findForm().vm.$emit('workItemCreated', { webUrl: '/' });

      expect(wrapper.find('h2').text()).toBe('New key result');
      expect(findTrigger().text()).toBe('New key result');
      expect(showToast).toHaveBeenCalledWith('Key result created', expect.any(Object));
    });
  });

  describe('CreateWorkItemCancelConfirmationModal', () => {
    it('confirmation modal is rendered but not visible initially', () => {
      createComponent();

      expect(findCancelConfirmationModal().exists()).toBe(true);
      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
    });

    it('confirmation modal is displayed over create modal when user clicks cancel on the form', async () => {
      createComponent();

      await wrapper.setProps({ visible: true });
      expect(findCreateModal().props('visible')).toBe(true);

      findForm().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);
      expect(findCreateModal().props('visible')).toBe(true);
    });

    it('confirmation modal closes when user clicks "Continue Editing" and create modal continues visible', async () => {
      createComponent();

      await wrapper.setProps({ visible: true });
      expect(findCreateModal().props('visible')).toBe(true);

      findForm().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);

      findCancelConfirmationModal().vm.$emit('continueEditing');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
      expect(findCreateModal().props('visible')).toBe(true);
    });
  });
});
