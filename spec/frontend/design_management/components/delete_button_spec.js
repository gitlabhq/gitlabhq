import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BatchDeleteButton from '~/design_management/components/delete_button.vue';

describe('Batch delete button component', () => {
  let wrapper;

  const findButton = () => wrapper.find(GlButton);
  const findModal = () => wrapper.find(GlModal);

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

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders non-disabled button by default', () => {
    createComponent();

    expect(findButton().exists()).toBe(true);
    expect(findButton().attributes('disabled')).toBeFalsy();
  });

  it('renders disabled button when design is deleting', () => {
    createComponent({ isDeleting: true });
    expect(findButton().attributes('disabled')).toBeTruthy();
  });

  it('emits `delete-selected-designs` event on modal ok click', () => {
    createComponent();
    findButton().vm.$emit('click');
    return wrapper.vm
      .$nextTick()
      .then(() => {
        findModal().vm.$emit('ok');
        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(wrapper.emitted('delete-selected-designs')).toBeTruthy();
      });
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
