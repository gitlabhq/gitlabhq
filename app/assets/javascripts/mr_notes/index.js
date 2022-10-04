import Vue from 'vue';
import store from '~/mr_notes/stores';
import initCherryPickCommitModal from '~/projects/commit/init_cherry_pick_commit_modal';
import initRevertCommitModal from '~/projects/commit/init_revert_commit_modal';
import initDiffsApp from '../diffs';
import { resetServiceWorkersPublicPath } from '../lib/utils/webpack';
import MergeRequest from '../merge_request';
import DiscussionCounter from '../notes/components/discussion_counter.vue';
import initNotesApp from './init_notes';

export default function initMrNotes() {
  resetServiceWorkersPublicPath();

  const mrShowNode = document.querySelector('.merge-request');
  // eslint-disable-next-line no-new
  new MergeRequest({
    action: mrShowNode.dataset.mrAction,
  });

  initDiffsApp(store);
  initNotesApp();

  document.addEventListener('merged:UpdateActions', () => {
    initRevertCommitModal('i_code_review_post_merge_submit_revert_modal');
    initCherryPickCommitModal('i_code_review_post_merge_submit_cherry_pick_modal');
  });

  requestIdleCallback(() => {
    const el = document.getElementById('js-vue-discussion-counter');

    if (el) {
      const { blocksMerge } = el.dataset;

      // eslint-disable-next-line no-new
      new Vue({
        el,
        name: 'DiscussionCounter',
        components: {
          DiscussionCounter,
        },
        store,
        render(createElement) {
          return createElement('discussion-counter', {
            props: {
              blocksMerge: blocksMerge === 'true',
            },
          });
        },
      });
    }
  });
}
