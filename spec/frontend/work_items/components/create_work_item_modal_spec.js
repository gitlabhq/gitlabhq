import { nextTick } from 'vue';
import { GlDisclosureDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';

const showToast = jest.fn();

describe('CreateWorkItemModal', () => {
  let wrapper;

  const findTrigger = () => wrapper.find('[data-testid="new-epic-button"]');
  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(CreateWorkItem);

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(CreateWorkItemModal, {
      propsData,
      mocks: {
        $toast: {
          show: showToast,
        },
      },
    });
  };

  it('passes workItemTypeName to CreateWorkItem', () => {
    createComponent({ workItemTypeName: 'issue' });

    expect(findForm().props('workItemTypeName')).toBe('issue');
  });

  it('shows toast on workItemCreated', () => {
    createComponent();

    findForm().vm.$emit('workItemCreated', { webUrl: '/' });

    expect(showToast).toHaveBeenCalledWith('Item created', expect.any(Object));
  });

  describe('default trigger', () => {
    it('opens modal on trigger click', async () => {
      createComponent();

      findTrigger().vm.$emit('click');

      await nextTick();

      expect(findModal().props('visible')).toBe(true);
    });
  });

  describe('dropdown item trigger', () => {
    it('renders a dropdown item component', () => {
      createComponent({ asDropdownItem: true });

      expect(findDropdownItem().exists()).toBe(true);
    });
  });

  it('closes modal on cancel event from form', () => {
    createComponent();

    findForm().vm.$emit('cancel');

    expect(findModal().props('visible')).toBe(false);
  });
});
