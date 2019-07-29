import { BLACK, COMMENT_BOX, MUTED } from '../shared';
import { clearSavedComment } from './comment_storage';
import { clearNote, postError } from './note';
import { selectCommentBox, selectCommentButton, selectNote, selectNoteContainer } from './utils';

const resetCommentButton = () => {
  const commentButton = selectCommentButton();

  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
  commentButton.innerText = 'Send feedback';
  commentButton.classList.replace('gitlab-button-secondary', 'gitlab-button-success');
  commentButton.style.opacity = 1;
};

const resetCommentBox = () => {
  const commentBox = selectCommentBox();
  commentBox.style.pointerEvents = 'auto';
  commentBox.style.color = BLACK;
};

const resetCommentText = () => {
  const commentBox = selectCommentBox();
  commentBox.value = '';
  clearSavedComment();
};

const resetComment = () => {
  resetCommentButton();
  resetCommentBox();
  resetCommentText();
};

const confirmAndClear = feedbackInfo => {
  const commentButton = selectCommentButton();
  const currentNote = selectNote();
  const noteContainer = selectNoteContainer();

  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
  commentButton.innerText = 'Feedback sent';
  noteContainer.style.visibility = 'visible';
  currentNote.insertAdjacentHTML('beforeend', feedbackInfo);

  setTimeout(resetComment, 1000);
  setTimeout(clearNote, 6000);
};

const setInProgressState = () => {
  const commentButton = selectCommentButton();
  const commentBox = selectCommentBox();

  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
  commentButton.innerText = 'Sending feedback';
  commentButton.classList.replace('gitlab-button-success', 'gitlab-button-secondary');
  commentButton.style.opacity = 0.5;
  commentBox.style.color = MUTED;
  commentBox.style.pointerEvents = 'none';
};

const commentErrors = error => {
  switch (error.status) {
    case 401:
      /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
      return 'Unauthorized. You may have entered an incorrect authentication token.';
    case 404:
      /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
      return 'Not found. You may have entered an incorrect merge request ID.';
    default:
      /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
      return `Your comment could not be sent. Please try again. Error: ${error.message}`;
  }
};

const postComment = ({
  platform,
  browser,
  userAgent,
  innerWidth,
  innerHeight,
  projectId,
  projectPath,
  mergeRequestId,
  mrUrl,
  token,
}) => {
  // Clear any old errors
  clearNote(COMMENT_BOX);

  setInProgressState();

  const commentText = selectCommentBox().value.trim();
  // Get the href at the last moment to support SPAs
  const { href } = window.location;

  if (!commentText) {
    /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
    postError('Your comment appears to be empty.', COMMENT_BOX);
    resetCommentBox();
    resetCommentButton();
    return;
  }

  const detailText = `
 \n
<details>
  <summary>Metadata</summary>
  Posted from ${href} | ${platform} | ${browser} | ${innerWidth} x ${innerHeight}.
  <br /><br />
  <em>User agent: ${userAgent}</em>
</details>
  `;

  const url = `
    ${mrUrl}/api/v4/projects/${projectId}/merge_requests/${mergeRequestId}/discussions`;

  const body = `${commentText} ${detailText}`;

  fetch(url, {
    method: 'POST',
    headers: {
      'PRIVATE-TOKEN': token,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ body }),
  })
    .then(response => {
      if (response.ok) {
        return response.json();
      }

      throw response;
    })
    .then(data => {
      const commentId = data.notes[0].id;
      const feedbackLink = `${mrUrl}/${projectPath}/merge_requests/${mergeRequestId}#note_${commentId}`;
      const feedbackInfo = `Feedback sent. View at <a class="gitlab-link" href="${feedbackLink}">${projectPath} !${mergeRequestId} (comment ${commentId})</a>`;
      confirmAndClear(feedbackInfo);
    })
    .catch(err => {
      postError(commentErrors(err), COMMENT_BOX);
      resetCommentBox();
      resetCommentButton();
    });
};

export default postComment;
