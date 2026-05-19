import Vue, { watch } from 'vue';
import { MOUNTED } from '~/rapid_diffs/adapter_events';
import DiffFileDiscussions from '~/rapid_diffs/app/discussions/diff_file_discussions.vue';
import { apolloProvider } from '~/graphql_shared/issuable_client';

function provideAppData(appData) {
  return {
    discussions: appData.discussionsEndpoint,
    previewMarkdown: appData.previewMarkdownEndpoint,
    markdownDocs: appData.markdownDocsEndpoint,
    register: appData.registerPath,
    signIn: appData.signInPath,
    reportAbuse: appData.reportAbusePath,
  };
}

function mountFileDiscussionsApp({ container, oldPath, newPath, appData, store }) {
  if (container.destroyApp) return;
  const mountTarget = document.createElement('div');
  container.appendChild(mountTarget);
  const instance = new Vue({
    el: mountTarget,
    apolloProvider,
    name: 'DiffFileDiscussionsRoot',
    provide() {
      return {
        store,
        userPermissions: appData.userPermissions,
        endpoints: provideAppData(appData),
        noteableType: appData.noteableType,
        filePaths: { oldPath, newPath },
        linkedFileData: appData.linkedFileData,
        newCommentTemplatePaths: appData.newCommentTemplatePaths || [],
      };
    },
    render(h) {
      return h(DiffFileDiscussions, {
        on: {
          empty() {
            instance.$destroy();
            Object.assign(container, { destroyApp: undefined, innerHTML: '' });
          },
        },
      });
    },
  });
  Object.assign(container, { destroyApp: () => instance.$destroy() });
}

function focusForm(id) {
  document.querySelector(`[data-discussion-id="${id}"] textarea:not(.hidden)`)?.focus();
}

export const createFileDiscussionsAdapter = (store) => ({
  [MOUNTED](addCleanup) {
    const { diffElement, appData } = this;
    const { oldPath, newPath } = this.data;
    const fileCommentToggle = diffElement.querySelector('[data-click="fileComment"]');
    fileCommentToggle.disabled = false;
    fileCommentToggle.classList.remove('disabled');
    fileCommentToggle.removeAttribute('aria-disabled');
    const stopWatcher = watch(
      () => store.findAllFileDiscussionsForFile({ oldPath, newPath }),
      (matchedDiscussions) => {
        if (matchedDiscussions.length === 0) return;
        const container = diffElement.querySelector('[data-file-discussions]');
        if (!container) return;
        mountFileDiscussionsApp({ container, oldPath, newPath, appData, store });
      },
      { immediate: true },
    );
    addCleanup(() => {
      stopWatcher();
      diffElement.querySelector('[data-file-discussions]')?.destroyApp?.();
    });
  },
  clicks: {
    fileComment() {
      const { oldPath, newPath } = this.data;
      const existingFormId = store.addNewFileDiscussionForm({ oldPath, newPath });
      if (existingFormId) focusForm(existingFormId);
    },
  },
});
