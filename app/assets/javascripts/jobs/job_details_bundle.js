import { mapState } from 'vuex';
import Vue from 'vue';
import Job from '../job';
import JobHeader from './components/header.vue';
import DetailsBlock from './components/sidebar_details_block.vue';
import createStore from './store';

export default () => {
  const { dataset } = document.getElementById('js-job-details-vue');

  // eslint-disable-next-line no-new
  new Job();

  const store = createStore();
  store.dispatch('setJobEndpoint', dataset.endpoint);
  store.dispatch('fetchJob');

  // Header
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-build-header-vue',
    components: {
      JobHeader,
    },
    store,
    computed: {
      ...mapState(['job', 'isLoading']),
    },
    render(createElement) {
      return createElement('job-header', {
        props: {
          isLoading: this.isLoading,
          job: this.job,
        },
      });
    },
  });

  // Sidebar information block
  const detailsBlockElement = document.getElementById('js-details-block-vue');
  const detailsBlockDataset = detailsBlockElement.dataset;
  // eslint-disable-next-line
  new Vue({
    el: detailsBlockElement,
    components: {
      DetailsBlock,
    },
    store,
    computed: {
      ...mapState(['job', 'isLoading']),
    },
    render(createElement) {
      return createElement('details-block', {
        props: {
          isLoading: this.isLoading,
          job: this.job,
          runnerHelpUrl: dataset.runnerHelpUrl,
          terminalPath: detailsBlockDataset.terminalPath,
        },
      });
    },
  });
};
