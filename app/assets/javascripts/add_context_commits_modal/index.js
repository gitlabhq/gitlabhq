import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import AddContextCommitsModalTrigger from './components/add_context_commits_modal_trigger.vue';
import AddContextCommitsModalWrapper from './components/add_context_commits_modal_wrapper.vue';
import createStore from './store';

export default function initAddContextCommitsTriggers() {
  const addContextCommitsModalTriggerEl = document.querySelector('.add-review-item-modal-trigger');
  const addContextCommitsModalWrapperEl = document.querySelector('.add-review-item-modal-wrapper');

  if (addContextCommitsModalTriggerEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: addContextCommitsModalTriggerEl,
      data() {
        const { commitsEmpty, contextCommitsEmpty } = this.$options.el.dataset;
        return {
          commitsEmpty: parseBoolean(commitsEmpty),
          contextCommitsEmpty: parseBoolean(contextCommitsEmpty),
        };
      },
      render(createElement) {
        return createElement(AddContextCommitsModalTrigger, {
          props: {
            commitsEmpty: this.commitsEmpty,
            contextCommitsEmpty: this.contextCommitsEmpty,
          },
        });
      },
    });
  }

  if (addContextCommitsModalWrapperEl) {
    const store = createStore();

    // eslint-disable-next-line no-new
    new Vue({
      el: addContextCommitsModalWrapperEl,
      store,
      data() {
        const { contextCommitsPath, targetBranch, mergeRequestIid, projectId } =
          this.$options.el.dataset;
        return {
          contextCommitsPath,
          targetBranch,
          mergeRequestIid: Number(mergeRequestIid),
          projectId: Number(projectId),
        };
      },
      render(createElement) {
        return createElement(AddContextCommitsModalWrapper, {
          props: {
            contextCommitsPath: this.contextCommitsPath,
            targetBranch: this.targetBranch,
            mergeRequestIid: this.mergeRequestIid,
            projectId: this.projectId,
          },
        });
      },
    });
  }
}
