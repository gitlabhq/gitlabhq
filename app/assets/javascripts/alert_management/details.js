import Vue from 'vue';
import AlertDetails from './components/alert_details.vue';

export default selector => {
  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    components: {
      AlertDetails,
    },
    render(createElement) {
      return createElement('alert-details', {});
    },
  });
};
