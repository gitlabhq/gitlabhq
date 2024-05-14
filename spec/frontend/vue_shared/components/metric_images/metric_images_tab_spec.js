import { GlFormInput, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import merge from 'lodash/merge';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import MetricImagesTable from '~/vue_shared/components/metric_images/metric_images_table.vue';
import MetricImagesTab from '~/vue_shared/components/metric_images/metric_images_tab.vue';
import createStore from '~/vue_shared/components/metric_images/store';
import waitForPromises from 'helpers/wait_for_promises';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { fileList, initialData } from './mock_data';

const service = {
  getMetricImages: jest.fn(),
};

const mockEvent = { preventDefault: jest.fn() };

Vue.use(Vuex);

describe('Metric images tab', () => {
  let wrapper;
  let store;

  const mountComponent = (options = {}) => {
    store = createStore({}, service);

    wrapper = shallowMount(
      MetricImagesTab,
      merge(
        {
          store,
          provide: {
            canUpdate: true,
            iid: initialData.issueIid,
            projectId: initialData.projectId,
          },
        },
        options,
      ),
    );
  };

  beforeEach(() => {
    mountComponent();
  });

  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const findImages = () => wrapper.findAllComponents(MetricImagesTable);
  const findModal = () => wrapper.findComponent(GlModal);
  const submitModal = () => findModal().vm.$emit('primary', mockEvent);
  const cancelModal = () => findModal().vm.$emit('hidden');

  describe('empty state', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the upload component', () => {
      expect(findUploadDropzone().exists()).toBe(true);
    });
  });

  describe('permissions', () => {
    beforeEach(() => {
      mountComponent({ provide: { canUpdate: false } });
    });

    it('hides the upload component when disallowed', () => {
      expect(findUploadDropzone().exists()).toBe(false);
    });
  });

  describe('onLoad action', () => {
    it('should load images', async () => {
      service.getMetricImages.mockImplementation(() => Promise.resolve(fileList));

      mountComponent();

      await waitForPromises();

      expect(findImages().length).toBe(1);
    });
  });

  describe('add metric dialog', () => {
    const testUrl = 'https://valid-url.com';

    it('should open the add metric dialog when clicked', async () => {
      mountComponent();

      findUploadDropzone().vm.$emit('change');

      await waitForPromises();

      expect(findModal().attributes('visible')).toBe('true');
    });

    it('should close when cancelled', async () => {
      mountComponent({
        data() {
          return { modalVisible: true };
        },
      });

      cancelModal();

      await waitForPromises();

      expect(findModal().attributes('visible')).toBeUndefined();
    });

    it('should add files and url when selected', async () => {
      mountComponent({
        data() {
          return { modalVisible: true, modalUrl: testUrl, currentFiles: fileList };
        },
      });

      const dispatchSpy = jest.spyOn(store, 'dispatch');

      submitModal();

      await waitForPromises();

      expect(dispatchSpy).toHaveBeenCalledWith('uploadImage', {
        files: fileList,
        url: testUrl,
        urlText: '',
      });
    });

    describe('url field', () => {
      beforeEach(() => {
        mountComponent({
          data() {
            return { modalVisible: true, modalUrl: testUrl };
          },
        });
      });

      it('should display the url field', () => {
        expect(wrapper.find('#upload-url-input').attributes('value')).toBe(testUrl);
      });

      it('should display a description of the url field', () => {
        const urlGroup = wrapper.find('#upload-url-group');
        expect(urlGroup.attributes('description')).toBe('Must start with http:// or https://');
      });

      it('should display the url text field', () => {
        expect(wrapper.find('#upload-text-input').attributes('value')).toBe('');
      });

      it('should clear url when cancelled', async () => {
        cancelModal();

        await waitForPromises();

        expect(wrapper.findComponent(GlFormInput).attributes('value')).toBe('');
      });

      it('should clear url when submitted', async () => {
        submitModal();

        await waitForPromises();

        expect(wrapper.findComponent(GlFormInput).attributes('value')).toBe('');
      });

      describe('is invalid', () => {
        beforeEach(() => {
          mountComponent({
            data() {
              return { modalVisible: true };
            },
          });

          const urlInput = wrapper.find('#upload-url-input');
          urlInput.vm.$emit('input', 'invalid-url');
          urlInput.vm.$emit('blur');
        });

        it('should disable the upload button', () => {
          const uploadButton = findModal().props('actionPrimary');
          expect(uploadButton.attributes.disabled).toBe(true);
        });

        it('should have an error state', () => {
          const urlGroup = wrapper.find('#upload-url-group');
          const urlInput = wrapper.find('#upload-url-input');

          expect(urlGroup.attributes('state')).toBe(undefined);
          expect(urlGroup.attributes('invalid-feedback')).toBe('Invalid URL');
          expect(urlInput.attributes('state')).toBe(undefined);
        });
      });
    });
  });
});
