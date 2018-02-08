import Vue from 'vue';
import JobMediator from './job_details_mediator';
import jobHeader from './components/header.vue';
import detailsBlock from './components/sidebar_details_block.vue';

document.addEventListener('DOMContentLoaded', () => {
  const dataset = document.getElementById('js-job-details-vue').dataset;
  const mediator = new JobMediator({ endpoint: dataset.endpoint });

  mediator.fetchJob();

  // Header
  Vue.create({
    el: '#js-build-header-vue',
    components: {
      jobHeader,
    },
    data() {
      return {
        mediator,
      };
    },
    mounted() {
      this.mediator.initBuildClass();
    },
    render(createElement) {
      return createElement('job-header', {
        props: {
          isLoading: this.mediator.state.isLoading,
          job: this.mediator.store.state.job,
        },
      });
    },
  });

  // Sidebar information block
  Vue.create({
    el: '#js-details-block-vue',
    components: {
      detailsBlock,
    },
    data() {
      return {
        mediator,
      };
    },
    render(createElement) {
      return createElement('details-block', {
        props: {
          isLoading: this.mediator.state.isLoading,
          job: this.mediator.store.state.job,
        },
      });
    },
  });
});
