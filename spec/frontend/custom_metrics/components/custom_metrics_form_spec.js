import { shallowMount } from '@vue/test-utils';
import CustomMetricsForm from '~/custom_metrics/components/custom_metrics_form.vue';

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
    wrapper = shallowMount(CustomMetricsForm, {
      propsData: {
        customMetricsPath: '',
        editProjectServicePath: '',
        metricPersisted,
        validateQueryPath: '',
        formData,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Computed', () => {
    it('Form button and title text indicate the custom metric is being edited', () => {
      mountComponent({ metricPersisted: true });

      expect(wrapper.vm.saveButtonText).toBe('Save Changes');
      expect(wrapper.vm.titleText).toBe('Edit metric');
    });

    it('Form button and title text indicate the custom metric is being created', () => {
      mountComponent({ metricPersisted: false });

      expect(wrapper.vm.saveButtonText).toBe('Create metric');
      expect(wrapper.vm.titleText).toBe('New metric');
    });
  });
});
