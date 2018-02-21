import Pipelines from '~/pipelines';

export default () => {
  const { controllerAction } = document.querySelector('.js-pipeline-container').dataset;
  const pipelineStatusUrl = `${document.querySelector('.js-pipeline-tab-link a').getAttribute('href')}/status.json`;

  new Pipelines({ // eslint-disable-line no-new
    initTabs: true,
    pipelineStatusUrl,
    tabsOptions: {
      action: controllerAction,
      defaultAction: 'pipelines',
      parentEl: '.pipelines-tabs',
    },
  });
};
