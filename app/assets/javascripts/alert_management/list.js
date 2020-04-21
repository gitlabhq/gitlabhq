import Vue from 'vue';
import AlertManagementList from './components/alert_management_list.vue';

export default () => {
  const selector = '#js-alert_management';

  const domEl = document.querySelector(selector);
  const { indexPath, enableAlertManagementPath, emptyAlertSvgPath } = domEl.dataset;

  return new Vue({
    el: selector,
    components: {
      AlertManagementList,
    },
    render(createElement) {
      return createElement('alert-management-list', {
        props: {
          indexPath,
          enableAlertManagementPath,
          emptyAlertSvgPath,
        },
      });
    },
  });
};
