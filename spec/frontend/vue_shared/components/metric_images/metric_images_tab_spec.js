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
import MetricImageDetailsModal from '~/vue_shared/components/metric_images/metric_image_details_modal.vue';
import { fileList, initialData } from './mock_data';

const service = {
  getMetricImages: jest.fn(),
};

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
  const findImageDetailsModal = () => wrapper.findComponent(MetricImageDetailsModal);
  const cancelModal = () => findImageDetailsModal().vm.$emit('hidden');

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

  describe('metric image details dialog', () => {
    it('should open when clicked', async () => {
      mountComponent();

      findUploadDropzone().vm.$emit('change');

      await waitForPromises();

      expect(findImageDetailsModal().attributes('visible')).toBe('true');
    });

    it('should close when cancelled', async () => {
      mountComponent({
        data() {
          return { modalVisible: true };
        },
      });

      cancelModal();

      await waitForPromises();

      expect(findImageDetailsModal().attributes('visible')).toBeUndefined();
    });
  });
});
