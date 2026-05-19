import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';

import IntegrationSectionAppleAppStore from '~/integrations/edit/components/sections/apple_app_store.vue';
import UploadDropzoneField from '~/integrations/edit/components/upload_dropzone_field.vue';
import { useIntegrationForm } from '~/integrations/edit/store';

Vue.use(PiniaVuePlugin);

describe('IntegrationSectionAppleAppStore', () => {
  let wrapper;

  const createComponent = (componentFields) => {
    const pinia = createTestingPinia({ stubActions: false });
    const store = useIntegrationForm();
    Object.assign(store, {
      customState: { ...componentFields },
    });

    wrapper = shallowMount(IntegrationSectionAppleAppStore, {
      pinia,
    });
  };

  const componentFields = (fileName = '') => {
    return {
      fields: [
        {
          name: 'app_store_private_key_file_name',
          value: fileName,
        },
      ],
    };
  };

  const findUploadDropzoneField = () => wrapper.findComponent(UploadDropzoneField);

  describe('computed properties', () => {
    it('renders UploadDropzoneField with default values', () => {
      createComponent(componentFields());

      const field = findUploadDropzoneField();

      expect(field.exists()).toBe(true);
      expect(field.props()).toMatchObject({
        label: 'The Apple App Store Connect Private Key (.p8)',
        helpText: '',
      });
    });

    it('renders UploadDropzoneField with custom values for an attached file', () => {
      createComponent(componentFields('fileName.txt'));

      const field = findUploadDropzoneField();

      expect(field.exists()).toBe(true);
      expect(field.props()).toMatchObject({
        label: 'Upload a new Apple App Store Connect Private Key (replace fileName.txt)',
        helpText: 'Leave empty to use your current Private Key.',
      });
    });
  });
});
