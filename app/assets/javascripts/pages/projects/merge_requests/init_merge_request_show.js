import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { s__ } from '~/locale';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { initPipelineCountListener } from '~/commit/pipelines/utils';
import { initIssuableSidebar } from '~/issuable';
import MergeRequestHeader from '~/merge_requests/components/merge_request_header.vue';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import initSourcegraph from '~/sourcegraph';
import ZenMode from '~/zen_mode';
import initAwardsApp from '~/emoji/awards_app';
import MrWidgetHowToMergeModal from '~/vue_merge_request_widget/components/mr_widget_how_to_merge_modal.vue';
import { initMrExperienceSurvey } from '~/surveys/merge_request_experience';
import toast from '~/vue_shared/plugins/global_toast';
import getStateQuery from './queries/get_state.query.graphql';

export default function initMergeRequestShow(store) {
  new ZenMode(); // eslint-disable-line no-new
  initPipelineCountListener(document.querySelector('#commit-pipeline-table-view'));
  addShortcutsExtension(ShortcutsIssuable);
  initSourcegraph();
  initIssuableSidebar();
  initAwardsApp(document.getElementById('js-vue-awards-block'));
  initMrExperienceSurvey();

  const el = document.querySelector('.js-mr-header');
  const { hidden, iid, projectPath, state } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'MergeRequestHeaderRoot',
    store,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: {
      query: getStateQuery,
      hidden: parseBoolean(hidden),
      iid,
      projectPath,
    },
    render(createElement) {
      return createElement(MergeRequestHeader, {
        props: {
          initialState: state,
        },
      });
    },
  });

  const modalEl = document.getElementById('js-check-out-modal');

  // eslint-disable-next-line no-new
  new Vue({
    el: modalEl,
    render(h) {
      return h(MrWidgetHowToMergeModal, {
        props: {
          canMerge: modalEl.dataset.canMerge === 'true',
          isFork: modalEl.dataset.isFork === 'true',
          sourceBranch: modalEl.dataset.sourceBranch,
          sourceProjectPath: modalEl.dataset.sourceProjectPath,
          targetBranch: modalEl.dataset.targetBranch,
          sourceProjectDefaultUrl: modalEl.dataset.sourceProjectDefaultUrl,
          reviewingDocsPath: modalEl.dataset.reviewingDocsPath,
        },
      });
    },
  });

  const copyReferenceButton = document.querySelector('.js-copy-reference');

  copyReferenceButton?.addEventListener('click', () => {
    toast(s__('MergeRequests|Reference copied'));
  });
}
