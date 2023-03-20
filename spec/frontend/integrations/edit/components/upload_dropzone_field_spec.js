import { mount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';

import UploadDropzoneField from '~/integrations/edit/components/upload_dropzone_field.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { mockField } from '../mock_data';

describe('UploadDropzoneField', () => {
  let wrapper;

  const contentsInputName = 'service[app_store_private_key]';
  const fileNameInputName = 'service[app_store_private_key_file_name]';

  const createComponent = (props) => {
    wrapper = mount(UploadDropzoneField, {
      propsData: {
        ...mockField,
        ...props,
        name: contentsInputName,
        label: 'Input Label',
        fileInputName: fileNameInputName,
      },
    });
  };

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const findFileContentsHiddenInput = () => wrapper.find(`input[name="${contentsInputName}"]`);
  const findFileNameHiddenInput = () => wrapper.find(`input[name="${fileNameInputName}"]`);

  describe('template', () => {
    it('adds the expected file inputFieldName', () => {
      createComponent();

      expect(findUploadDropzone().props('inputFieldName')).toBe('service[dropzone_file_name]');
    });

    it('adds a disabled, hidden text input for the file contents', () => {
      createComponent();

      expect(findFileContentsHiddenInput().attributes('name')).toBe(contentsInputName);
      expect(findFileContentsHiddenInput().attributes('disabled')).toBeDefined();
    });

    it('adds a disabled, hidden text input for the file name', () => {
      createComponent();

      expect(findFileNameHiddenInput().attributes('name')).toBe(fileNameInputName);
      expect(findFileNameHiddenInput().attributes('disabled')).toBeDefined();
    });
  });

  describe('clearError', () => {
    it('clears uploadError when called', async () => {
      createComponent();

      expect(findGlAlert().exists()).toBe(false);

      findUploadDropzone().vm.$emit('error');
      await nextTick();

      expect(findGlAlert().exists()).toBe(true);
      expect(findGlAlert().text()).toBe(
        'Error: You are trying to upload something other than an allowed file.',
      );

      findGlAlert().vm.$emit('dismiss');
      await nextTick();

      expect(findGlAlert().exists()).toBe(false);
    });
  });

  describe('onError', () => {
    it('assigns uploadError to the supplied custom message', async () => {
      const message = 'test error message';
      createComponent({ errorMessage: message });

      findUploadDropzone().vm.$emit('error');

      await nextTick();

      expect(findGlAlert().exists()).toBe(true);
      expect(findGlAlert().text()).toBe(message);
    });
  });
});
