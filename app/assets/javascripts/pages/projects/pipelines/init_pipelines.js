import Pipelines from '~/pipelines';

export default () => {
  const mergeRequestListToggle = document.querySelector('.js-toggle-mr-list');
  const truncatedMergeRequestList = document.querySelector('.js-truncated-mr-list');
  const fullMergeRequestList = document.querySelector('.js-full-mr-list');

  if (mergeRequestListToggle) {
    mergeRequestListToggle.addEventListener('click', (e) => {
      e.preventDefault();
      truncatedMergeRequestList.classList.toggle('hide');
      fullMergeRequestList.classList.toggle('hide');
    });
  }

  const pipelineTabLink = document.querySelector('.js-pipeline-tab-link a');
  const { controllerAction } = document.querySelector('.js-pipeline-container').dataset;

  if (pipelineTabLink) {
    const pipelineStatusUrl = `${pipelineTabLink.getAttribute('href')}/status.json`;

    // eslint-disable-next-line no-new
    new Pipelines({
      initTabs: true,
      pipelineStatusUrl,
      tabsOptions: {
        action: controllerAction,
        defaultAction: 'pipelines',
        parentEl: '.pipelines-tabs',
      },
    });
  }
};
