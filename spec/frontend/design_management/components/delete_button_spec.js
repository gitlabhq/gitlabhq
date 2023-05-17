import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import BatchDeleteButton from '~/design_management/components/delete_button.vue';

describe('Batch delete button component', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(GlModal);

  function createComponent({ isDeleting = false } = {}, { slots = {} } = {}) {
    wrapper = shallowMount(BatchDeleteButton, {
      propsData: {
        isDeleting,
      },
      directives: {
        GlModalDirective,
      },
      slots,
    });
  }

  it('renders non-disabled button by default', () => {
    createComponent();

    expect(findButton().exists()).toBe(true);
    expect(findButton().attributes('disabled')).toBeUndefined();
  });

  it('renders disabled button when design is deleting', () => {
    createComponent({ isDeleting: true });
    expect(findButton().attributes('disabled')).toBeDefined();
  });

  it('emits `delete-selected-designs` event on modal ok click', async () => {
    createComponent();
    findButton().vm.$emit('click');

    await nextTick();
    findModal().vm.$emit('ok');

    await nextTick();
    expect(wrapper.emitted('delete-selected-designs')).toHaveLength(1);
  });

  it('renders slot content', () => {
    const testText = 'Archive selected';
    createComponent(
      {},
      {
        slots: {
          default: testText,
        },
      },
    );

    expect(findButton().text()).toBe(testText);
  });
});
