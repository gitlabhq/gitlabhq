export function setPositionDataAttribute(el, options) {
  // Update position data attribute so that the
  // new comment form can use this data for ajax request
  const { x, y, width, height } = options;
  const position = el.dataset.position;
  const positionObject = JSON.parse(position);
  positionObject.x_axis = x;
  positionObject.y_axis = y;
  positionObject.width = width;
  positionObject.height = height;

  el.setAttribute('data-position', JSON.stringify(positionObject));
}

export function updateAvatarBadgeNumber(discussionEl, newBadgeNumber) {
  const avatarBadges = discussionEl.querySelectorAll('.image-diff-avatar-link .badge');

  [].map.call(avatarBadges, avatarBadge =>
    Object.assign(avatarBadge, {
      innerText: newBadgeNumber,
    }),
  );
}

export function updateDiscussionBadgeNumber(discussionEl, newBadgeNumber) {
  const discussionBadgeEl = discussionEl.querySelector('.badge');
  discussionBadgeEl.innerText = newBadgeNumber;
}

export function toggleCollapsed(event) {
  const toggleButtonEl = event.currentTarget;
  toggleButtonEl.closest('.discussion-notes').classList.toggle('collapsed');
}
