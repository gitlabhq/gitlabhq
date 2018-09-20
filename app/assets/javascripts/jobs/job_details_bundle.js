import Vue from 'vue';
import JobMediator from './job_details_mediator';
import jobHeader from './components/header.vue';
import detailsBlock from './components/sidebar_details_block.vue';
import JobApp from './components/job_app.vue';

export default () => {
  const { dataset } = document.getElementById('js-job-details-vue');
  const mediator = new JobMediator({ endpoint: dataset.endpoint });

  mediator.fetchJob();

  const datasetJob = document.getElementById('js-vue-job-app').dataset;

  // NEW APP
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-vue-job-app',
    components: {
      JobApp,
    },
    render(createElement) {
      return createElement('job-app', {
        props: {
          jobEndpoint: datasetJob.jobEndpoint,
          traceOptions: {
            buildStage: datasetJob.traceOptionsBuildStage,
            buildStatus: datasetJob.traceOptionsBuildStatus,
            logState: datasetJob.traceOptionsLogState,
            pagePath: datasetJob.traceOptionsPagePath,
          },
          containerClass: datasetJob.containerClass,
        },
      });
    },
  });

  // Header
  // eslint-disable-next-line no-new
  // new Vue({
  //   el: '#js-build-header-vue',
  //   components: {
  //     jobHeader,
  //   },
  //   data() {
  //     return {
  //       mediator,
  //     };
  //   },
  //   mounted() {
  //     this.mediator.initBuildClass();
  //   },
  //   render(createElement) {
  //     return createElement('job-header', {
  //       props: {
  //         isLoading: this.mediator.state.isLoading,
  //         job: this.mediator.store.state.job,
  //       },
  //     });
  //   },
  // });

  // Sidebar information block
  const detailsBlockElement = document.getElementById('js-details-block-vue');
  const detailsBlockDataset = detailsBlockElement.dataset;
  // eslint-disable-next-line
  new Vue({
    el: detailsBlockElement,
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
          runnerHelpUrl: dataset.runnerHelpUrl,
          terminalPath: detailsBlockDataset.terminalPath,
        },
      });
    },
  });
};
