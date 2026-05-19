import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';

import IntegrationSectionGooglePlay from '~/integrations/edit/components/sections/google_play.vue';
import UploadDropzoneField from '~/integrations/edit/components/upload_dropzone_field.vue';
import { useIntegrationForm } from '~/integrations/edit/store';

Vue.use(PiniaVuePlugin);

describe('IntegrationSectionGooglePlay', () => {
  let wrapper;

  const createComponent = (fileName = '') => {
    const pinia = createTestingPinia({ stubActions: false });
    const store = useIntegrationForm();
    Object.assign(store, {
      customState: {
        fields: [
          {
            name: 'service_account_key_file_name',
            value: fileName,
          },
        ],
      },
    });

    wrapper = shallowMount(IntegrationSectionGooglePlay, {
      pinia,
    });
  };

  const findUploadDropzoneField = () => wrapper.findComponent(UploadDropzoneField);

  describe('computed properties', () => {
    it('renders UploadDropzoneField with default values', () => {
      createComponent();

      const field = findUploadDropzoneField();

      expect(field.exists()).toBe(true);
      expect(field.props()).toMatchObject({
        label: 'Service account key (.JSON)',
        helpText: '',
      });
    });

    it('renders UploadDropzoneField with custom values for an attached file', () => {
      createComponent('fileName.txt');

      const field = findUploadDropzoneField();

      expect(field.exists()).toBe(true);
      expect(field.props()).toMatchObject({
        label: 'Upload a new service account key (replace fileName.txt)',
        helpText: 'Leave empty to use your current service account key.',
      });
    });
  });
});
