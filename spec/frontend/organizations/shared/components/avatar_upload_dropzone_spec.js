import { GlAvatar, GlButton, GlTruncate } from '@gitlab/ui';
import { nextTick } from 'vue';
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

  const createComponent = ({ propsData = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(AvatarUploadDropzone, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      stubs,
    });
  };

  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const findButton = () => wrapper.findComponent(GlButton);
  const findError = () => wrapper.find('p.gl-text-danger');

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

  it('renders `UploadDropzone` that updates the file input on drop so it submits with the form', () => {
    createComponent();

    expect(findUploadDropzone().props('shouldUpdateInputOnFileDrop')).toBe(true);
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

    it('hides upload dropzone', () => {
      expect(findUploadDropzone().isVisible()).toBe(false);
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

  describe('avatar validation', () => {
    const sizeErrorMessage = 'The file is too large. The maximum file size allowed is 200 KiB.';
    const typeErrorMessage =
      'The file format is not supported. Please try one of the following formats: png, jpg, jpeg, gif, bmp, tiff, ico, webp';

    it.each`
      description                                       | fileName     | fileType        | fileSize      | expectedError
      ${'a file over the size limit'}                   | ${'big.png'} | ${'image/png'}  | ${201 * 1024} | ${sizeErrorMessage}
      ${'a disallowed MIME type and extension'}         | ${'foo.txt'} | ${'text/plain'} | ${10}         | ${typeErrorMessage}
      ${'an allowed MIME type'}                         | ${'foo'}     | ${'image/png'}  | ${10}         | ${null}
      ${'a disallowed MIME type but allowed extension'} | ${'foo.jpg'} | ${'text/plain'} | ${10}         | ${null}
      ${'a file at exactly the size limit'}             | ${'ok.png'}  | ${'image/png'}  | ${200 * 1024} | ${null}
    `(
      'renders the correct feedback for $description',
      async ({ fileName, fileType, fileSize, expectedError }) => {
        const testFile = new File([new Uint8Array(fileSize)], fileName, { type: fileType });
        createComponent();

        findUploadDropzone().vm.$emit('change', testFile);
        await nextTick();

        if (expectedError) {
          expect(findError().text()).toBe(expectedError);
          expect(wrapper.emitted('input')).toBeUndefined();
        } else {
          expect(findError().exists()).toBe(false);
          expect(wrapper.emitted('input')).toEqual([[testFile]]);
        }
      },
    );

    it('clears the error when a subsequent file is valid', async () => {
      const invalidFile = new File([new Uint8Array(10)], 'foo.txt', { type: 'text/plain' });
      const validFile = new File([new Uint8Array(10)], 'foo.png', { type: 'image/png' });
      createComponent();

      findUploadDropzone().vm.$emit('change', invalidFile);
      await nextTick();
      expect(findError().exists()).toBe(true);

      findUploadDropzone().vm.$emit('change', validFile);
      await nextTick();
      expect(findError().exists()).toBe(false);
    });

    it('announces the error to screen readers', async () => {
      const invalidFile = new File([new Uint8Array(10)], 'foo.txt', { type: 'text/plain' });
      createComponent();

      findUploadDropzone().vm.$emit('change', invalidFile);
      await nextTick();

      expect(findError().attributes('role')).toBe('alert');
    });

    describe('when `UploadDropzone` emits `error` without a validation error', () => {
      it('renders a generic upload error', async () => {
        createComponent();

        findUploadDropzone().vm.$emit('error');
        await nextTick();

        expect(findError().text()).toBe('Failed to upload avatar. Please try again.');
      });
    });

    describe('when a re-selection fails while a file is staged', () => {
      it('discards the staged file so it matches the cleared native input', async () => {
        createComponent({ propsData: { value: file } });

        findUploadDropzone().vm.$emit('error');
        await nextTick();

        expect(wrapper.emitted('input')).toEqual([[null]]);
      });
    });

    describe('when an error occurs without a staged file', () => {
      it('does not emit `input`', async () => {
        createComponent();

        findUploadDropzone().vm.$emit('error');
        await nextTick();

        expect(wrapper.emitted('input')).toBeUndefined();
      });
    });
  });

  describe('native file input syncing', () => {
    const clearInputFiles = jest.fn();
    const UploadDropzoneStub = {
      name: 'UploadDropzone',
      template: '<div></div>',
      methods: { clearInputFiles },
    };

    beforeEach(() => {
      clearInputFiles.mockClear();
    });

    it('clears the dropzone file input when the value is discarded', async () => {
      createComponent({ stubs: { UploadDropzone: UploadDropzoneStub } });

      wrapper.setProps({ value: file });
      await nextTick();
      expect(clearInputFiles).not.toHaveBeenCalled();

      wrapper.setProps({ value: null });
      await nextTick();
      expect(clearInputFiles).toHaveBeenCalled();
    });

    it('clears the dropzone file input when a selected file fails validation', async () => {
      // `acceptAnyFile` bypasses UploadDropzone's internal validation (and its
      // input clearing), so rejecting the file here must clear the input.
      const invalidFile = new File([new Uint8Array(10)], 'foo.txt', { type: 'text/plain' });
      createComponent({ stubs: { UploadDropzone: UploadDropzoneStub } });

      wrapper.findComponent(UploadDropzoneStub).vm.$emit('change', invalidFile);
      await nextTick();

      expect(clearInputFiles).toHaveBeenCalled();
    });

    it('clears the dropzone file input when the dropzone reports an error', async () => {
      createComponent({ stubs: { UploadDropzone: UploadDropzoneStub } });

      wrapper.findComponent(UploadDropzoneStub).vm.$emit('error');
      await nextTick();

      expect(clearInputFiles).toHaveBeenCalled();
    });
  });

  describe('removability', () => {
    const persistedUrl = 'https://example.com/avatar.png';

    it('shows the remove button and hides the dropzone for a removable persisted avatar', () => {
      createComponent({ propsData: { value: persistedUrl, canRemove: true } });

      expect(findButton().exists()).toBe(true);
      expect(findUploadDropzone().isVisible()).toBe(false);
    });

    it('hides the remove button and keeps the dropzone for a non-removable persisted avatar', () => {
      createComponent({ propsData: { value: persistedUrl, canRemove: false } });

      expect(findButton().exists()).toBe(false);
      expect(findUploadDropzone().isVisible()).toBe(true);
    });

    it('always allows discarding a locally selected file', async () => {
      createComponent({ propsData: { canRemove: false } });

      wrapper.setProps({ value: file });
      await nextTick();

      expect(findButton().exists()).toBe(true);
    });
  });

  describe('label association', () => {
    it('associates the label with the dropzone file input', () => {
      createComponent();

      const label = wrapper.find('label');
      expect(label.attributes('for')).toBe(findUploadDropzone().props('inputFieldId'));
      expect(findUploadDropzone().props('inputFieldId')).toEqual(expect.any(String));
    });
  });
});
