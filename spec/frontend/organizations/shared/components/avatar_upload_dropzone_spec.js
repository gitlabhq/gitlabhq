import { GlAvatar, GlButton, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AvatarUploadDropzone from '~/organizations/shared/components/avatar_upload_dropzone.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

describe('AvatarUploadDropzone', () => {
  let wrapper;

  const defaultPropsData = {
    entity: { id: 1, name: 'Foo' },
    value: null,
    label: 'Avatar',
  };

  const file = new File(['foo'], 'foo.jpg', {
    type: 'text/plain',
  });
  const file2 = new File(['bar'], 'bar.jpg', {
    type: 'text/plain',
  });
  const blob = 'blob:http://127.0.0.1:3000/0046cf8c-ea21-4720-91ef-2e354d570c75';

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(AvatarUploadDropzone, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    window.URL.createObjectURL = jest.fn().mockImplementation(() => blob);
    window.URL.revokeObjectURL = jest.fn();
  });

  it('renders `GlAvatar` with correct props', () => {
    createComponent();

    expect(wrapper.findComponent(GlAvatar).props()).toMatchObject({
      entityId: defaultPropsData.entity.id,
      entityName: defaultPropsData.entity.name,
      shape: AVATAR_SHAPE_OPTION_RECT,
      size: 96,
      src: null,
    });
  });

  it('renders label', () => {
    createComponent();

    expect(wrapper.findByText(defaultPropsData.label).exists()).toBe(true);
  });

  describe('when `value` prop is updated', () => {
    beforeEach(() => {
      createComponent();

      // setProps is justified here because we are testing the component's
      // reactive behavior which constitutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({ value: file });
    });

    it('updates `GlAvatar` `src` prop', () => {
      expect(wrapper.findComponent(GlAvatar).props('src')).toBe(blob);
    });

    it('renders remove button', () => {
      expect(findButton().exists()).toBe(true);
    });

    it('renders truncated file name', () => {
      expect(wrapper.findComponent(GlTruncate).props('text')).toBe('foo.jpg');
    });

    it('does not render upload dropzone', () => {
      expect(findUploadDropzone().exists()).toBe(false);
    });

    describe('when `value` prop is updated a second time', () => {
      beforeEach(() => {
        wrapper.setProps({ value: file2 });
      });

      it('revokes the object URL of the previous avatar', () => {
        expect(window.URL.revokeObjectURL).toHaveBeenCalledWith(blob);
      });
    });

    describe('when avatar is removed', () => {
      beforeEach(() => {
        findButton().vm.$emit('click');
      });

      it('emits `input` event with `null` payload', () => {
        expect(wrapper.emitted('input')).toEqual([[null]]);
      });
    });
  });

  describe('when `UploadDropzone` emits `change` event', () => {
    beforeEach(() => {
      createComponent();
      findUploadDropzone().vm.$emit('change', file);
    });

    it('emits `input` event', () => {
      expect(wrapper.emitted('input')).toEqual([[file]]);
    });
  });
});
