import { nextTick } from 'vue';
import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

describe('CreateWorkItemModal', () => {
  let wrapper;

  const findTrigger = () => wrapper.find('[data-testid="new-epic-button"]');
  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(CreateWorkItem);

  const createComponent = ({ workItemType } = {}) => {
    wrapper = shallowMount(CreateWorkItemModal, {
      propsData: {
        workItemType,
      },
    });
  };

  it('passes workItemType to CreateWorkItem', () => {
    createComponent({ workItemType: 'issue' });

    expect(findForm().props('workItemType')).toBe('issue');
  });

  it('calls visitUrl on workItemCreated', () => {
    createComponent();

    findForm().vm.$emit('workItemCreated', { webUrl: '/' });

    expect(visitUrl).toHaveBeenCalledWith('/');
  });

  it('opens modal on trigger click', async () => {
    createComponent();

    findTrigger().vm.$emit('click');

    await nextTick();

    expect(findModal().props('visible')).toBe(true);
  });

  it('closes modal on cancel event from form', () => {
    createComponent();

    findForm().vm.$emit('cancel');

    expect(findModal().props('visible')).toBe(false);
  });
});
