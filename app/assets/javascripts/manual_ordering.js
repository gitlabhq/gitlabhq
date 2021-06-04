import Sortable from 'sortablejs';
import {
  getBoardSortableDefaultOptions,
  sortableStart,
} from '~/boards/mixins/sortable_default_options';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';

const updateIssue = (url, issueList, { move_before_id, move_after_id }) =>
  axios
    .put(`${url}/reorder`, {
      move_before_id,
      move_after_id,
      group_full_path: issueList.dataset.groupFullPath,
    })
    .catch(() => {
      createFlash({
        message: s__("ManualOrdering|Couldn't save the order of the issues"),
      });
    });

const initManualOrdering = (draggableSelector = 'li.issue') => {
  const issueList = document.querySelector('.manual-ordering');

  if (!issueList || !(gon.current_user_id > 0)) {
    return;
  }

  Sortable.create(
    issueList,
    getBoardSortableDefaultOptions({
      scroll: true,
      fallbackTolerance: 1,
      dataIdAttr: 'data-id',
      fallbackOnBody: false,
      group: {
        name: 'issues',
      },
      draggable: draggableSelector,
      onStart: () => {
        sortableStart();
      },
      onUpdate: (event) => {
        const el = event.item;

        const url = el.getAttribute('url') || el.dataset.url;

        const prev = el.previousElementSibling;
        const next = el.nextElementSibling;

        const beforeId = prev && parseInt(prev.dataset.id, 10);
        const afterId = next && parseInt(next.dataset.id, 10);

        updateIssue(url, issueList, { move_after_id: afterId, move_before_id: beforeId });
      },
    }),
  );
};

export default initManualOrdering;
