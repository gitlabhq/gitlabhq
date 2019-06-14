import { BLACK, COMMENT_BOX, MUTED, LOGOUT } from './constants';
import { clearNote, note, postError } from './note';
import { buttonClearStyles, selectCommentBox, selectCommentButton, selectNote } from './utils';

const comment = `
  <div>
    <textarea id="${COMMENT_BOX}" name="${COMMENT_BOX}" rows="3" placeholder="Enter your feedback or idea" class="gitlab-input" aria-required="true"></textarea>
    ${note}
    <p class="gitlab-metadata-note">Additional metadata will be included: browser, OS, current page, user agent, and viewport dimensions.</p>
  </div>
  <div class="gitlab-button-wrapper">
    <button class="gitlab-button gitlab-button-secondary" style="${buttonClearStyles}" type="button" id="${LOGOUT}"> Logout </button>
    <button class="gitlab-button gitlab-button-success" style="${buttonClearStyles}" type="button" id="gitlab-comment-button"> Send feedback </button>
  </div>
`;

const resetCommentBox = () => {
  const commentBox = selectCommentBox();
  const commentButton = selectCommentButton();

  commentButton.innerText = 'Send feedback';
  commentButton.classList.replace('gitlab-button-secondary', 'gitlab-button-success');
  commentButton.style.opacity = 1;

  commentBox.style.pointerEvents = 'auto';
  commentBox.style.color = BLACK;
};

const resetCommentButton = () => {
  const commentBox = selectCommentBox();
  const currentNote = selectNote();

  commentBox.value = '';
  currentNote.innerText = '';
};

const resetComment = () => {
  resetCommentBox();
  resetCommentButton();
};

const confirmAndClear = mergeRequestId => {
  const commentButton = selectCommentButton();
  const currentNote = selectNote();

  commentButton.innerText = 'Feedback sent';
  currentNote.innerText = `Your comment was successfully posted to merge request #${mergeRequestId}`;
  setTimeout(resetComment, 2000);
};

const setInProgressState = () => {
  const commentButton = selectCommentButton();
  const commentBox = selectCommentBox();

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
  mergeRequestId,
  mrUrl,
  token,
}) => {
  // Clear any old errors
  clearNote(COMMENT_BOX);

  setInProgressState();

  const commentText = selectCommentBox().value.trim();

  if (!commentText) {
    postError('Your comment appears to be empty.', COMMENT_BOX);
    resetCommentBox();
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
        confirmAndClear(mergeRequestId);
        return;
      }

      throw new Error(`${response.status}: ${response.statusText}`);
    })
    .catch(err => {
      postError(
        `Your comment could not be sent. Please try again. Error: ${err.message}`,
        COMMENT_BOX,
      );
      resetCommentBox();
    });
};

export { comment, postComment };
