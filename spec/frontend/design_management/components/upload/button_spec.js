import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UploadButton from '~/design_management/components/upload/button.vue';

describe('Design management upload button component', () => {
  let wrapper;

  function createComponent({ isSaving = false, isInverted = false } = {}) {
    wrapper = shallowMount(UploadButton, {
      propsData: {
        isSaving,
        isInverted,
      },
    });
  }

  it('renders upload design button', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders inverted upload design button', () => {
    createComponent({ isInverted: true });

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when `isSaving` prop is `true`', () => {
    it('Button `loading` prop is `true`', () => {
      createComponent({ isSaving: true });

      const button = wrapper.findComponent(GlButton);
      expect(button.exists()).toBe(true);
      expect(button.props('loading')).toBe(true);
    });
  });

  describe('onFileUploadChange', () => {
    it('emits upload event', () => {
      createComponent();

      wrapper.vm.onFileUploadChange({ target: { files: 'test' } });

      expect(wrapper.emitted().upload[0]).toEqual(['test']);
    });
  });

  describe('openFileUpload', () => {
    it('triggers click on input', () => {
      createComponent();

      const clickSpy = jest.spyOn(wrapper.find('input').element, 'click');

      wrapper.vm.openFileUpload();

      expect(clickSpy).toHaveBeenCalled();
    });
  });
});
