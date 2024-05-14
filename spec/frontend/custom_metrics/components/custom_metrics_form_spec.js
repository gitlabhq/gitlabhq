import CustomMetricsForm from '~/custom_metrics/components/custom_metrics_form.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('CustomMetricsForm', () => {
  let wrapper;

  function mountComponent({
    metricPersisted = false,
    formData = {
      title: '',
      query: '',
      yLabel: '',
      unit: '',
      group: '',
      legend: '',
    },
  }) {
    wrapper = shallowMountExtended(CustomMetricsForm, {
      propsData: {
        customMetricsPath: '',
        editIntegrationPath: '',
        metricPersisted,
        validateQueryPath: '',
        formData,
      },
    });
  }

  const findHeader = () => wrapper.findByTestId('metrics-header');
  const findSaveButton = () => wrapper.findByTestId('metrics-save-button');

  describe('Computed', () => {
    it('Form button and title text indicate the custom metric is being edited', () => {
      mountComponent({ metricPersisted: true });

      expect(findHeader().text()).toBe('Edit metric');
      expect(findSaveButton().text()).toBe('Save Changes');
    });

    it('Form button and title text indicate the custom metric is being created', () => {
      mountComponent({ metricPersisted: false });

      expect(findSaveButton().text()).toBe('Create metric');
      expect(findHeader().text()).toBe('New metric');
    });
  });
});
