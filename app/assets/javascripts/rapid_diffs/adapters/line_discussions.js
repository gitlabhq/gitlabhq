import Vue, { watch } from 'vue';
import { MOUNTED, HIGHLIGHT_LINES, CLEAR_HIGHLIGHT } from '~/rapid_diffs/adapter_events';
import DiffDiscussionRow from '~/rapid_diffs/app/discussions/diff_discussion_row.vue';
import {
  getLineNumbers,
  getLineChange,
  getLineCode,
  getNewLineRangeContent,
  findLineRow,
} from '~/rapid_diffs/utils/line_utils';
import { createAlert } from '~/alert';
import { pinia } from '~/pinia/instance';
import { apolloProvider } from '~/graphql_shared/issuable_client';

function mountDiscussionRow({ lineRow, parallel, appData, store, trigger, id }) {
  if (lineRow.nextElementSibling?.dataset.discussionRow === 'true') return;
  const [rowOldLine, rowNewLine] = getLineNumbers(lineRow);
  const changed = lineRow.querySelector('[data-change]') !== null;
  const placeholder = lineRow.closest('tbody').insertRow(lineRow.sectionRowIndex + 1);
  const instance = new Vue({
    el: placeholder,
    pinia,
    apolloProvider,
    name: 'DiffDiscussionRowRoot',
    provide() {
      return {
        store,
        userPermissions: appData.userPermissions,
        endpoints: {
          discussions: appData.discussionsEndpoint,
          previewMarkdown: appData.previewMarkdownEndpoint,
          markdownDocs: appData.markdownDocsEndpoint,
          register: appData.registerPath,
          signIn: appData.signInPath,
          reportAbuse: appData.reportAbusePath,
        },
        noteableType: appData.noteableType,
        filePaths: { oldPath: appData.oldPath, newPath: appData.newPath },
        blobRawPath: appData.blobRawPath,
        suggestionsHelpPath: appData.suggestionsHelpPath,
        defaultSuggestionCommitMessage: appData.defaultSuggestionCommitMessage,
        linkedFileData: appData.linkedFileData,
        newCommentTemplatePaths: appData.newCommentTemplatePaths || [],
      };
    },
    render(h) {
      return h(DiffDiscussionRow, {
        props: {
          oldLine: rowOldLine,
          newLine: rowNewLine,
          parallel,
          changed,
        },
        on: {
          'start-thread': ({ oldPath, newPath, oldLine, newLine }) => {
            const side = newLine && !oldLine ? 'new' : 'old';
            const lineChange = getLineChange(lineRow.querySelector(`[data-position="${side}"]`));
            const lineCode = getLineCode({ id, row: lineRow, oldLine, newLine });
            const linePos = { old_line: oldLine, new_line: newLine };
            const lineRange = { start: linePos, end: linePos };
            const lines = getNewLineRangeContent(lineRow.closest('table'), lineRange, side);
            store.addNewLineDiscussionForm({
              oldPath,
              newPath,
              lineChange,
              lineCode,
              lineRange,
              extraOptions: { lines },
            });
          },
          empty() {
            trigger(CLEAR_HIGHLIGHT);
            instance.$destroy();
            instance.$el.remove();
          },
          highlight(lineRange) {
            trigger(HIGHLIGHT_LINES, lineRange);
          },
          'clear-highlight': () => {
            trigger(CLEAR_HIGHLIGHT);
          },
        },
      });
    },
  });
  const row = instance.$el;
  // In Vue 3, createApp().mount(el) renders inside el rather than replacing it.
  // This results in a nested <tr> inside the placeholder <tr>.
  // Detect and fix by replacing the outer <tr> with the inner one.
  if (row.parentNode?.tagName === 'TR') {
    row.parentNode.replaceWith(row);
  }
  row.destroy = () => instance.$destroy();
}

export const createLineDiscussionsAdapter = ({ store, parallel, errorMessage }) => ({
  [MOUNTED](addCleanup) {
    const { diffElement, appData, trigger, id } = this;
    const { oldPath, newPath, blobRawPath } = this.data;
    const stopWatcher = watch(
      () => store.findLinePositionsForFile({ oldPath, newPath }),
      (matchedPositions) => {
        matchedPositions.forEach((position) => {
          try {
            const lineRow = findLineRow(diffElement, position.old_line, position.new_line);
            if (!lineRow) return;
            mountDiscussionRow({
              lineRow,
              parallel,
              appData: { ...appData, oldPath, newPath, blobRawPath },
              store,
              trigger,
              id,
            });
          } catch (error) {
            createAlert({
              message: errorMessage,
              parent: diffElement,
              error,
              captureError: true,
            });
          }
        });
      },
      { immediate: true },
    );
    addCleanup(() => {
      stopWatcher();
      diffElement.querySelectorAll('[data-discussion-row]').forEach((row) => {
        row.destroy?.();
      });
    });
  },
  clicks: {
    newDiscussion(event, button) {
      const lineChange = getLineChange(button.closest('[data-position]'));
      const row = button.closest('tr');
      const [oldLine, newLine] = getLineNumbers(row);
      const { oldPath, newPath } = this.data;
      const lineCode = getLineCode({ id: this.id, row, oldLine, newLine });
      const lines = getNewLineRangeContent(this.diffElement, button.lineRange, lineChange.position);
      const existingDiscussionId = store.addNewLineDiscussionForm({
        oldPath,
        newPath,
        lineChange,
        lineCode,
        lineRange: button.lineRange,
        extraOptions: { lines },
      });
      if (existingDiscussionId) {
        document
          .querySelector(`[data-discussion-id="${existingDiscussionId}"] textarea:not(.hidden)`)
          ?.focus();
      }
    },
  },
});
