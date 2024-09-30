import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UploadButton from '~/work_items/components/design_management/upload_button.vue';

describe('Design management upload button component', () => {
  let wrapper;

  const findInput = () => wrapper.find('input');
  const findButton = () => wrapper.findComponent(GlButton);

  function createComponent({ isSaving = false } = {}) {
    wrapper = shallowMount(UploadButton, {
      propsData: {
        isSaving,
      },
    });
  }

  it('renders upload design button', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when `isSaving` prop is `true`', () => {
    it('Button `loading` prop is `true`', () => {
      createComponent({ isSaving: true });

      expect(findButton().exists()).toBe(true);
      expect(findButton().props('loading')).toBe(true);
    });
  });

  describe('onFileUploadChange', () => {
    it('emits upload event', async () => {
      createComponent();

      const file = 'test';
      Object.defineProperty(findInput().element, 'files', { value: [file] });
      findInput().trigger('change', file);
      await nextTick();

      expect(wrapper.emitted().upload[0]).toEqual([[file]]);
    });
  });

  describe('openFileUpload', () => {
    it('triggers click on input', async () => {
      createComponent();

      const clickSpy = jest.spyOn(findInput().element, 'click');

      findButton().vm.$emit('click');
      await nextTick();

      expect(clickSpy).toHaveBeenCalled();
    });
  });
});
