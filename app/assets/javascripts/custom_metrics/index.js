import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import CustomMetricsForm from './components/custom_metrics_form.vue';

export default () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-custom-metrics',
    components: {
      CustomMetricsForm,
    },
    render(createElement) {
      const domEl = document.querySelector(this.$options.el);
      const {
        customMetricsPath,
        editIntegrationPath,
        validateQueryPath,
        title,
        query,
        yLabel,
        unit,
        group,
        legend,
      } = domEl.dataset;
      let { metricPersisted } = domEl.dataset;

      metricPersisted = parseBoolean(metricPersisted);

      return createElement('custom-metrics-form', {
        props: {
          customMetricsPath,
          metricPersisted,
          editIntegrationPath,
          validateQueryPath,
          formData: {
            title,
            query,
            yLabel,
            unit,
            group,
            legend,
          },
        },
      });
    },
  });
};
