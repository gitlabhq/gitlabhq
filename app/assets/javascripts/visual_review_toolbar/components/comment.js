import { nextView } from '../store';
import { localStorage, COMMENT_BOX, LOGOUT, STORAGE_MR_ID, STORAGE_TOKEN } from '../shared';
import { clearNote } from './note';
import { buttonClearStyles } from './utils';
import { addForm } from './wrapper';
import { changeSelectedMr, selectedMrNote } from './comment_mr_note';
import postComment from './comment_post';
import { saveComment, getSavedComment } from './comment_storage';

const comment = state => {
  const savedComment = getSavedComment();

  return `
    <div>
      <textarea id="${COMMENT_BOX}" name="${COMMENT_BOX}" rows="3" placeholder="Enter your feedback or idea" class="gitlab-input" aria-required="true">${savedComment}</textarea>
      ${selectedMrNote(state)}
      <p class="gitlab-metadata-note">Additional metadata will be included: browser, OS, current page, user agent, and viewport dimensions.</p>
    </div>
    <div class="gitlab-button-wrapper">
      <button class="gitlab-button gitlab-button-success" style="${buttonClearStyles}" type="button" id="gitlab-comment-button"> Send feedback </button>
      <button class="gitlab-button gitlab-button-secondary" style="${buttonClearStyles}" type="button" id="${LOGOUT}"> Log out </button>
    </div>
  `;
};

// This function is here becaause it is called only from the comment view
// If we reach a design where we can logout from multiple views, promote this
// to it's own package
const logoutUser = state => {
  localStorage.removeItem(STORAGE_TOKEN);
  localStorage.removeItem(STORAGE_MR_ID);
  state.token = '';
  state.mergeRequestId = '';

  clearNote();
  addForm(nextView(state, COMMENT_BOX));
};

export { changeSelectedMr, comment, logoutUser, postComment, saveComment };
