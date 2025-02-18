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
import { initMrExperienceSurvey } from '~/surveys/merge_request_experience';
import toast from '~/vue_shared/plugins/global_toast';
import getStateQuery from './queries/get_state.query.graphql';
import initCheckoutModal from './init_checkout_modal';

export default function initMergeRequestShow(store, pinia) {
  new ZenMode(); // eslint-disable-line no-new
  initPipelineCountListener(document.querySelector('#commit-pipeline-table-view'));
  addShortcutsExtension(ShortcutsIssuable);
  initSourcegraph();
  initIssuableSidebar();
  initAwardsApp(document.getElementById('js-vue-awards-block'));
  initMrExperienceSurvey();
  initCheckoutModal();

  const el = document.querySelector('.js-mr-header');
  const { hidden, imported, iid, projectPath, state } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'MergeRequestHeaderRoot',
    pinia,
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
          isImported: parseBoolean(imported),
        },
      });
    },
  });

  const copyReferenceButton = document.querySelector('.js-copy-reference');

  copyReferenceButton?.addEventListener('click', () => {
    toast(s__('MergeRequests|Reference copied'));
  });
}
