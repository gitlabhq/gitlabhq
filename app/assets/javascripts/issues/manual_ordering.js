import Sortable from 'sortablejs';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import { getSortableDefaultOptions, sortableStart } from '~/sortable/utils';

const updateIssue = (url, { move_before_id, move_after_id }) =>
  axios
    .put(`${url}/reorder`, {
      move_before_id,
      move_after_id,
    })
    .catch(() => {
      createAlert({
        message: s__("ManualOrdering|Couldn't save the order of the issues"),
      });
    });

const initManualOrdering = () => {
  const issueList = document.querySelector('.manual-ordering');

  if (!issueList || !(gon.current_user_id > 0)) {
    return;
  }

  Sortable.create(
    issueList,
    getSortableDefaultOptions({
      scroll: true,
      fallbackTolerance: 1,
      dataIdAttr: 'data-id',
      fallbackOnBody: false,
      group: {
        name: 'issues',
      },
      draggable: 'li.issue',
      onStart: () => {
        sortableStart();
      },
      onUpdate: (event) => {
        const el = event.item;

        const url = el.getAttribute('url');

        const prev = el.previousElementSibling;
        const next = el.nextElementSibling;

        const beforeId = prev && parseInt(prev.dataset.id, 10);
        const afterId = next && parseInt(next.dataset.id, 10);

        updateIssue(url, { move_after_id: afterId, move_before_id: beforeId });
      },
    }),
  );
};

export default initManualOrdering;
