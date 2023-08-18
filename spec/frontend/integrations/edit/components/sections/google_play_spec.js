import { shallowMount } from '@vue/test-utils';

import IntegrationSectionGooglePlay from '~/integrations/edit/components/sections/google_play.vue';
import UploadDropzoneField from '~/integrations/edit/components/upload_dropzone_field.vue';
import { createStore } from '~/integrations/edit/store';

describe('IntegrationSectionGooglePlay', () => {
  let wrapper;

  const createComponent = (fileName = '') => {
    const store = createStore({
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
      store,
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
