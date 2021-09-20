export function initPipelineCountListener(el) {
  if (!el) return;

  el.addEventListener('update-pipelines-count', (event) => {
    if (event.detail.pipelineCount) {
      const badge = document.querySelector('.js-pipelines-mr-count');

      badge.textContent = event.detail.pipelineCount;
    }
  });
}
