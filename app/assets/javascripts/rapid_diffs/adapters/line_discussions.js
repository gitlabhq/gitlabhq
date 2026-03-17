import Vue, { watch } from 'vue';
import { MOUNTED, HIGHLIGHT_LINES, CLEAR_HIGHLIGHT } from '~/rapid_diffs/adapter_events';
import DiffDiscussionRow from '~/rapid_diffs/app/discussions/diff_discussion_row.vue';

function getLineNumbers(row) {
  return [
    row.querySelector('[data-position="old"] [data-line-number]'),
    row.querySelector('[data-position="new"] [data-line-number]'),
  ].map((cell) => (cell ? Number(cell.dataset.lineNumber) : null));
}

function mountDiscussionRow({ lineRow, parallel, appData, store, trigger }) {
  if (lineRow.nextElementSibling?.dataset.discussionRow === 'true') return;
  const [oldLine, newLine] = getLineNumbers(lineRow);
  const changed = lineRow.querySelector('[data-change]') !== null;
  const placeholder = lineRow.closest('tbody').insertRow(lineRow.sectionRowIndex + 1);
  const instance = new Vue({
    el: placeholder,
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
      };
    },
    render(h) {
      return h(DiffDiscussionRow, {
        props: {
          oldPath: appData.oldPath,
          newPath: appData.newPath,
          oldLine,
          newLine,
          parallel,
          changed,
        },
        on: {
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

function findLineRow(element, oldLine, newLine) {
  return element
    .querySelector(
      `[data-position="${oldLine ? 'old' : 'new'}"] [data-line-number="${oldLine || newLine}"]`,
    )
    ?.closest('tr');
}

function focusForm(id) {
  document.querySelector(`[data-discussion-id="${id}"] textarea:not(.hidden)`)?.focus();
}

export const createLineDiscussionsAdapter = ({ store, parallel }) => ({
  [MOUNTED](addCleanup) {
    const { diffElement, appData, trigger } = this;
    const { oldPath, newPath } = this.data;
    const stopWatcher = watch(
      () => store.findAllDiscussionsForFile({ oldPath, newPath }),
      (matchedDiscussions) => {
        matchedDiscussions.forEach(({ position }) => {
          const lineRow = findLineRow(diffElement, position.old_line, position.new_line);
          if (!lineRow) return;
          mountDiscussionRow({
            lineRow,
            parallel,
            appData: { ...appData, oldPath, newPath },
            store,
            trigger,
          });
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
      const { oldPath, newPath } = this.data;
      const id = store.replyToLineDiscussion({ oldPath, newPath, lineRange: button.lineRange });
      if (id) focusForm(id);
    },
  },
});
