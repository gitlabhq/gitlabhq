import Vue from 'vue';
import { MOUNTED } from '~/rapid_diffs/adapter_events';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { pinia } from '~/pinia/instance';

function mountVueApp(el, id) {
  // eslint-disable-next-line no-new
  new Vue({
    el,
    pinia,
    computed: {
      // this way we ensure reactivity continues to work without rerendering the whole component
      discussion() {
        return useDiffDiscussions().getDiscussionById(id);
      },
    },
    render(h) {
      if (!this.discussion) return null;

      return h(
        'div',
        { attrs: { 'data-discussion-id': this.discussion.id } },
        `This is a discussion placeholder with an id: ${this.discussion.id}`,
      );
    },
  });
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
  return ({ diffElement, id, position }) => {
    if (document.querySelector(`[data-discussion-id="${id}"]`)) return;

    const cell = createCell(diffElement, position.old_line, position.new_line);
    const mountTarget = document.createElement('div');
    cell.appendChild(mountTarget);
    mountVueApp(mountTarget, id);
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

export const parallelDiscussionsAdapter = {
  [MOUNTED](addCleanup) {
    const { diffElement } = this;
    addCleanup(
      createDiscussionsWatcher(this.data.oldPath, this.data.newPath, ({ id, position }) => {
        mountParallelDiscussion({ diffElement, id, position });
      }),
    );
  },
};

export const inlineDiscussionsAdapter = {
  [MOUNTED](addCleanup) {
    const { diffElement } = this;
    addCleanup(
      createDiscussionsWatcher(this.data.oldPath, this.data.newPath, ({ id, position }) => {
        mountInlineDiscussion({ diffElement, id, position });
      }),
    );
  },
};
