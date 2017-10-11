export function setPositionDataAttribute(el, options) {
  // Update position data attribute so that the
  // new comment form can use this data for ajax request
  const { x, y, width, height } = options;
  const position = el.dataset.position;
  const positionObject = Object.assign({}, JSON.parse(position), {
    x,
    y,
    width,
    height,
  });

  el.setAttribute('data-position', JSON.stringify(positionObject));
}

export function updateDiscussionAvatarBadgeNumber(discussionEl, newBadgeNumber) {
  const avatarBadgeEl = discussionEl.querySelector('.image-diff-avatar-link .badge');
  avatarBadgeEl.innerText = newBadgeNumber;
}

export function updateDiscussionBadgeNumber(discussionEl, newBadgeNumber) {
  const discussionBadgeEl = discussionEl.querySelector('.badge');
  discussionBadgeEl.innerText = newBadgeNumber;
}

export function toggleCollapsed(event) {
  const toggleButtonEl = event.currentTarget;
  const discussionNotesEl = toggleButtonEl.closest('.discussion-notes');
  const formEl = discussionNotesEl.querySelector('.discussion-form');
  const isCollapsed = discussionNotesEl.classList.contains('collapsed');

  if (isCollapsed) {
    discussionNotesEl.classList.remove('collapsed');
  } else {
    discussionNotesEl.classList.add('collapsed');
  }

  // Override the inline display style set in notes.js
  if (formEl && !isCollapsed) {
    formEl.style.display = 'none';
  } else if (formEl && isCollapsed) {
    formEl.style.display = 'block';
  }
}
