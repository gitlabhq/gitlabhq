import Vue from 'vue';
import commitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';
import BlobViewer from '~/blob/viewer/index';
import initBlob from '~/pages/projects/init_blob';
import glBreadcrumb from '@gitlab-org/gitlab-ui/components/breadcrumb.vue';

document.addEventListener('DOMContentLoaded', () => {
  new BlobViewer(); // eslint-disable-line no-new
  initBlob();

  const CommitPipelineStatusEl = document.querySelector('.js-commit-pipeline-status');
  const statusLink = document.querySelector('.commit-actions .ci-status-link');
  if (statusLink) {
    statusLink.remove();
    // eslint-disable-next-line no-new
    new Vue({
      el: CommitPipelineStatusEl,
      components: {
        commitPipelineStatus,
      },
      render(createElement) {
        return createElement('commit-pipeline-status', {
          props: {
            endpoint: CommitPipelineStatusEl.dataset.endpoint,
          },
        });
      },
    });
  }

  const repoBreadcrumbs = document.querySelector('.js-repo-breadcrumb');

  if (repoBreadcrumbs) {
    const { breadcrumbs, rootPath, treePath } = repoBreadcrumbs.dataset;
    const breadcrumbTitles = breadcrumbs.split('/');

    const items = [{
      text: rootPath,
      href: treePath,
    }].concat(breadcrumbTitles.map((text, index) => {
      return {
        text,
        href: `${treePath}/${breadcrumbTitles.slice(0, index + 1).join('/')}`,
      };
    }));

    new Vue({
      el: repoBreadcrumbs,
      components: {
        glBreadcrumb,
      },
      render(createElement) {
        return createElement('gl-breadcrumb', {
          props: {
            items,
          },
        });
      }
    })
  }
});
