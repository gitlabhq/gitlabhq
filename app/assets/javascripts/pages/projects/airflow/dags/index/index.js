import Vue from 'vue';
import AirflowDags from '~/airflow/dags/components/dags.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const initShowDags = () => {
  const element = document.querySelector('#js-show-airflow-dags');
  if (!element) {
    return null;
  }

  const dags = JSON.parse(element.dataset.dags);
  const pagination = convertObjectPropsToCamelCase(JSON.parse(element.dataset.pagination));

  return new Vue({
    el: element,
    render(h) {
      return h(AirflowDags, {
        props: {
          dags,
          pagination,
        },
      });
    },
  });
};

initShowDags();
