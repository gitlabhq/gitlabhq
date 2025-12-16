import Vue from 'vue';
import { MOUNTED } from '~/rapid_diffs/adapter_events';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { pinia } from '~/pinia/instance';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import NewLineDiscussionForm from '~/rapid_diffs/app/discussions/new_line_discussion_form.vue';

function mountVueApp(el, id, appData) {
  // eslint-disable-next-line no-new
  new Vue({
    el,
    pinia,
    provide() {
      return {
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
    computed: {
      // this way we ensure reactivity continues to work without rerendering the whole component
      discussion() {
        return useDiffDiscussions().getDiscussionById(id);
      },
    },
    render(h) {
      if (!this.discussion) return null;

      if (this.discussion.hidden) return null;

      if (this.discussion.isForm) {
        return h(NewLineDiscussionForm, { props: { discussion: this.discussion } });
      }

      return h(DiffDiscussions, { props: { discussions: [this.discussion] } });
    },
  });
}

function getLineNumbers(row) {
  return [
    row.querySelector('[data-position="old"] [data-line-number]'),
    row.querySelector('[data-position="new"] [data-line-number]'),
  ].map((cell) => (cell ? Number(cell.dataset.lineNumber) : null));
}

function getInlinePosition(button) {
  return getLineNumbers(button.closest('tr'));
}

function getParallelPosition(button) {
  const cell = button.parentElement;
  const lineNumbers = getLineNumbers(cell.parentElement);
  const { change } = cell.dataset;
  if (change) return change === 'added' ? [null, lineNumbers[1]] : [lineNumbers[0], null];
  return lineNumbers;
}

function findLineRow(element, oldLine, newLine) {
  return element
    .querySelector(
      `[data-position="${oldLine ? 'old' : 'new'}"] [data-line-number="${oldLine || newLine}"]`,
    )
    .closest('tr');
}

function isValidDiscussionRow(row) {
  return row && row?.dataset.discussionRow === 'true';
}

function addDiscussionRow(lineRow) {
  const discussionRow = lineRow.closest('tbody').insertRow(lineRow.sectionRowIndex + 1);
  discussionRow.dataset.discussionRow = 'true';
  discussionRow.classList.add('rd-discussion-row');
  return discussionRow;
}

function addInlineCell(lineRow) {
  const maybeDiscussionRow = lineRow.nextElementSibling;
  if (isValidDiscussionRow(maybeDiscussionRow)) return maybeDiscussionRow.children[0];

  const newDiscussionRow = addDiscussionRow(lineRow);
  const discussionCell = document.createElement('td');
  discussionCell.colSpan = lineRow.querySelectorAll('td').length;

  newDiscussionRow.appendChild(discussionCell);
  return discussionCell;
}

function addParallelCells(lineRow) {
  const maybeDiscussionRow = lineRow.nextElementSibling;
  if (isValidDiscussionRow(maybeDiscussionRow))
    return [maybeDiscussionRow.children[0], maybeDiscussionRow.children[1]];

  const newDiscussionRow = addDiscussionRow(lineRow);

  const leftCell = document.createElement('td');
  const rightCell = document.createElement('td');
  const cellColSpan = lineRow.querySelectorAll('td').length / 2;
  leftCell.colSpan = cellColSpan;
  rightCell.colSpan = cellColSpan;

  newDiscussionRow.append(leftCell, rightCell);
  return [leftCell, rightCell];
}

function createDiscussionMount(createCell) {
  return ({ diffElement, id, position, appData }) => {
    if (document.querySelector(`[data-discussion-id="${id}"]`)) return;

    const cell = createCell(diffElement, position.old_line, position.new_line);
    if (cell.hasMountedApp) return;
    const mountTarget = document.createElement('div');
    cell.appendChild(mountTarget);
    cell.hasMountedApp = true;
    mountVueApp(mountTarget, id, appData);
  };
}

const mountParallelDiscussion = createDiscussionMount((diffElement, oldLine, newLine) => {
  const lineRow = findLineRow(diffElement, oldLine, newLine);
  let cell;

  if (oldLine && newLine) {
    cell = addInlineCell(lineRow, oldLine, newLine);
  } else {
    const [leftCell, rightCell] = addParallelCells(lineRow, oldLine, newLine);
    cell = oldLine ? leftCell : rightCell;
  }

  return cell;
});

const mountInlineDiscussion = createDiscussionMount((diffElement, oldLine, newLine) => {
  const lineRow = findLineRow(diffElement, oldLine, newLine);
  return addInlineCell(lineRow, oldLine, newLine);
});

function createDiscussionsWatcher(oldPath, newPath, callback) {
  const store = useDiffDiscussions(pinia);
  return store.$subscribe(
    () => {
      const matchedDiscussions = store.discussions.filter((discussion) => {
        return (
          discussion.diff_discussion &&
          discussion.position.old_path === oldPath &&
          discussion.position.new_path === newPath
        );
      });
      matchedDiscussions.forEach(callback);
    },
    { immediate: true },
  );
}

function focusForm(id) {
  document.querySelector(`[data-discussion-id="${id}"] textarea:not(.hidden)`)?.focus();
}

export const parallelDiscussionsAdapter = {
  [MOUNTED](addCleanup) {
    const { diffElement, appData } = this;
    addCleanup(
      createDiscussionsWatcher(this.data.oldPath, this.data.newPath, ({ id, position }) => {
        mountParallelDiscussion({ diffElement, id, position, appData });
      }),
    );
  },
  clicks: {
    newDiscussion(event, button) {
      const [oldLine, newLine] = getParallelPosition(button);
      const { oldPath, newPath } = this.data;
      const existingDiscussionId = useDiffDiscussions(pinia).addNewLineDiscussionForm({
        oldPath,
        newPath,
        oldLine,
        newLine,
      });
      if (existingDiscussionId) focusForm(existingDiscussionId);
    },
  },
};

export const inlineDiscussionsAdapter = {
  [MOUNTED](addCleanup) {
    const { diffElement, appData } = this;
    addCleanup(
      createDiscussionsWatcher(this.data.oldPath, this.data.newPath, ({ id, position }) => {
        mountInlineDiscussion({ diffElement, id, position, appData });
      }),
    );
  },
  clicks: {
    newDiscussion(event, button) {
      const [oldLine, newLine] = getInlinePosition(button);
      const { oldPath, newPath } = this.data;
      const existingDiscussionId = useDiffDiscussions(pinia).addNewLineDiscussionForm({
        oldPath,
        newPath,
        oldLine,
        newLine,
      });
      if (existingDiscussionId) focusForm(existingDiscussionId);
    },
  },
};
