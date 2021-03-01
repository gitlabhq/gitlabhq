import Vue from 'vue';
import ForkGroupsList from './components/fork_groups_list.vue';

const mountElement = document.getElementById('fork-groups-mount-element');
const { endpoint } = mountElement.dataset;
// eslint-disable-next-line no-new
new Vue({
  el: mountElement,
  render(h) {
    return h(ForkGroupsList, {
      props: {
        endpoint,
      },
    });
  },
});
