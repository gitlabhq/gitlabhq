import Vue from 'vue';
import Popover from './components/popover.vue';

export default el =>
  new Vue({
    el,
    render(createElement) {
      return createElement(Popover, {
        props: { dismissEndpoint: el.dataset.dismissEndpoint, featureId: el.dataset.featureId },
      });
    },
  });
