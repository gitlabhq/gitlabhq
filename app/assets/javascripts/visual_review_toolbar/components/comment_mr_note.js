import { nextView } from '../store';
import { localStorage, CHANGE_MR_ID_BUTTON, COMMENT_BOX } from '../shared';
import { clearNote } from './note';
import { buttonClearStyles } from './utils';
import { addForm } from './wrapper';

const selectedMrNote = state => {
  const { mrUrl, projectPath, mergeRequestId } = state;

  const mrLink = `${mrUrl}/${projectPath}/merge_requests/${mergeRequestId}`;

  return `
    <p class="gitlab-metadata-note">
      This posts to merge request <a class="gitlab-link" href="${mrLink}">!${mergeRequestId}</a>.
      <button style="${buttonClearStyles}" type="button" id="${CHANGE_MR_ID_BUTTON}" class="gitlab-link gitlab-link-button">Change</button>
    </p>
  `;
};

const clearMrId = state => {
  localStorage.removeItem('mergeRequestId');
  state.mergeRequestId = '';
};

const changeSelectedMr = state => {
  clearMrId(state);
  clearNote();
  addForm(nextView(state, COMMENT_BOX));
};

export { changeSelectedMr, selectedMrNote };
