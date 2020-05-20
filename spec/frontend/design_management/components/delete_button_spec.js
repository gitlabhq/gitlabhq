import { shallowMount } from '@vue/test-utils';
import { GlDeprecatedButton, GlModal, GlModalDirective } from '@gitlab/ui';
import BatchDeleteButton from '~/design_management/components/delete_button.vue';

describe('Batch delete button component', () => {
  let wrapper;

  const findButton = () => wrapper.find(GlDeprecatedButton);
  const findModal = () => wrapper.find(GlModal);

  function createComponent(isDeleting = false) {
    wrapper = shallowMount(BatchDeleteButton, {
      propsData: {
        isDeleting,
      },
      directives: {
        GlModalDirective,
      },
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
    createComponent(true);
    expect(findButton().attributes('disabled')).toBeTruthy();
  });

  it('emits `deleteSelectedDesigns` event on modal ok click', () => {
    createComponent();
    findButton().vm.$emit('click');
    return wrapper.vm
      .$nextTick()
      .then(() => {
        findModal().vm.$emit('ok');
        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(wrapper.emitted().deleteSelectedDesigns).toBeTruthy();
      });
  });
});
