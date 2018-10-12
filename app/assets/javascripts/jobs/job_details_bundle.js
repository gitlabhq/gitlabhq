import _ from 'underscore';
import { mapState, mapActions } from 'vuex';
import Vue from 'vue';
import Job from '../job';
import JobApp from './components/job_app.vue';
import Sidebar from './components/sidebar.vue';
import createStore from './store';

export default () => {
  const { dataset } = document.getElementById('js-job-details-vue');



  const store = createStore();
  store.dispatch('setJobEndpoint', dataset.endpoint);

  store.dispatch('fetchJob');

  // Header
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-build-header-vue',
    components: {
      JobApp,
    },
    store,
    computed: {
      ...mapState(['job', 'isLoading']),
    },
    render(createElement) {
      return createElement('job-app', {
        props: {
          isLoading: this.isLoading,
          job: this.job,
          runnerSettingsUrl: dataset.runnerSettingsUrl,
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
      Sidebar,
    },
    computed: {
      ...mapState(['job']),
    },
    watch: {
      job(newVal, oldVal) {
        if (_.isEmpty(oldVal) && !_.isEmpty(newVal.pipeline)) {
          this.fetchStages();
        }
      },
    },
    methods: {
      ...mapActions(['fetchStages']),
    },
    store,
    render(createElement) {
      return createElement('sidebar', {
        props: {
          runnerHelpUrl: dataset.runnerHelpUrl,
          terminalPath: detailsBlockDataset.terminalPath,
        },
      });
    },
  });

  // eslint-disable-next-line no-new
  new Job();
};
