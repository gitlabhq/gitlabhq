import { BLACK, COMMENT_BOX, MUTED, LOGOUT } from './constants';
import { clearNote, postError } from './note';
import {
  buttonClearStyles,
  selectCommentBox,
  selectCommentButton,
  selectNote,
  selectNoteContainer,
} from './utils';

const comment = `
  <div>
    <textarea id="${COMMENT_BOX}" name="${COMMENT_BOX}" rows="3" placeholder="Enter your feedback or idea" class="gitlab-input" aria-required="true"></textarea>
    <p class="gitlab-metadata-note">Additional metadata will be included: browser, OS, current page, user agent, and viewport dimensions.</p>
  </div>
  <div class="gitlab-button-wrapper">
    <button class="gitlab-button gitlab-button-secondary" style="${buttonClearStyles}" type="button" id="${LOGOUT}"> Log out </button>
    <button class="gitlab-button gitlab-button-success" style="${buttonClearStyles}" type="button" id="gitlab-comment-button"> Send feedback </button>
  </div>
`;

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

const postComment = ({
  href,
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

      throw new Error(`${response.status}: ${response.statusText}`);
    })
    .then(data => {
      const commentId = data.notes[0].id;
      const feedbackLink = `${mrUrl}/${projectPath}/merge_requests/${mergeRequestId}#note_${commentId}`;
      const feedbackInfo = `Feedback sent. View at <a class="gitlab-link" href="${feedbackLink}">${projectPath} #${mergeRequestId} (comment ${commentId})</a>`;
      confirmAndClear(feedbackInfo);
    })
    .catch(err => {
      postError(
        `Your comment could not be sent. Please try again. Error: ${err.message}`,
        COMMENT_BOX,
      );
      resetCommentBox();
      resetCommentButton();
    });
};

export { comment, postComment };
