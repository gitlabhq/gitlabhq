import ImageBadge from './image_badge';

export function getTargetSelection(event) {
  const containerEl = event.currentTarget;
  const imageEl = containerEl.querySelector('img');
  const x = event.offsetX ? (event.offsetX) : event.pageX - containerEl.offsetLeft;
  const y = event.offsetY ? (event.offsetY) : event.pageY - containerEl.offsetTop;

  const width = imageEl.width;
  const height = imageEl.height;

  const actualWidth = imageEl.naturalWidth;
  const actualHeight = imageEl.naturalHeight;

  const widthRatio = actualWidth / width;
  const heightRatio = actualHeight / height;

  // Browser will include the frame as a clickable target,
  // which would result in potential 1px out of bounds value
  // This bound the coordinates to inside the frame
  const normalizedX = Math.max(0, x) && Math.min(x, width);
  const normalizedY = Math.max(0, y) && Math.min(y, height);

  return {
    browser: {
      x: normalizedX,
      y: normalizedY,
      width,
      height,
    },
    actual: {
      // Round x, y so that we don't need to deal with decimals
      x: Math.round(normalizedX * widthRatio),
      y: Math.round(normalizedY * heightRatio),
      width: actualWidth,
      height: actualHeight,
    },
  };
}

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

export function commentIndicatorOnClick(e) {
  // Prevent from triggering onAddImageDiffNote in notes.js
  e.stopPropagation();

  const buttonEl = e.currentTarget;
  const diffViewerEl = buttonEl.closest('.diff-viewer');
  const textareaEl = diffViewerEl.querySelector('.note-container form .note-textarea');
  textareaEl.focus();
}

export function addCommentIndicator(containerEl, coordinate) {
  const { x, y } = coordinate;
  const buttonEl = document.createElement('button');
  buttonEl.classList.add('btn-transparent', 'comment-indicator');
  buttonEl.setAttribute('type', 'button');
  buttonEl.style.left = `${x}px`;
  buttonEl.style.top = `${y}px`;

  const imageEl = document.createElement('img');
  imageEl.classList.add('image-comment-dark');
  imageEl.src = '/assets/icon_image_comment_dark.svg';
  imageEl.alt = 'comment indicator';

  buttonEl.appendChild(imageEl);
  containerEl.appendChild(buttonEl);

  return buttonEl;
}

export function removeCommentIndicator(imageFrameEl) {
  const commentIndicatorEl = imageFrameEl.querySelector('.comment-indicator');
  const imageEl = imageFrameEl.querySelector('img');
  const willRemove = commentIndicatorEl;

  if (willRemove) {
    commentIndicatorEl.remove();
  }

  return {
    removed: willRemove,
    x: parseInt(commentIndicatorEl.style.left.replace('px', ''), 10),
    y: parseInt(commentIndicatorEl.style.top.replace('px', ''), 10),
    image: {
      width: imageEl.width,
      height: imageEl.height,
    },
  };
}

export function showCommentIndicator(imageFrameEl, coordinate) {
  const { x, y } = coordinate;
  const commentIndicatorEl = imageFrameEl.querySelector('.comment-indicator');

  if (commentIndicatorEl) {
    commentIndicatorEl.style.left = `${x}px`;
    commentIndicatorEl.style.top = `${y}px`;
  } else {
    const buttonEl = addCommentIndicator(imageFrameEl, coordinate);
    buttonEl.addEventListener('click', commentIndicatorOnClick);
  }
}

export function addCommentBadge(containerEl, { coordinate, badgeText, noteId }) {
  const { x, y } = coordinate;
  const buttonEl = document.createElement('button');
  buttonEl.classList.add('btn-transparent', 'badge');
  buttonEl.setAttribute('type', 'button');
  buttonEl.innerText = badgeText;

  containerEl.appendChild(buttonEl);

  // TODO: We should use math to calculate the width so that we don't
  // have to do a reflow here but we can leave this here for now

  // Set button center to be the center of the clicked position
  const { width, height } = buttonEl.getBoundingClientRect();
  buttonEl.style.left = `${x - (width * 0.5)}px`;
  buttonEl.style.top = `${y - (height * 0.5)}px`;

  buttonEl.addEventListener('click', (e) => {
    e.stopPropagation();
    window.location.hash = noteId;
  });

  return buttonEl;
}

export function addAvatarBadge(el, event) {
  const { noteId, badgeNumber } = event.detail;

  // Add badge to new comment
  const avatarBadgeEl = el.querySelector(`#${noteId} .badge`);
  avatarBadgeEl.innerText = badgeNumber;
  avatarBadgeEl.classList.remove('hidden');
}

export function generateBadgeFromDiscussionDOM(imageFrameEl, discussionEl) {
  const position = JSON.parse(discussionEl.dataset.position);
  const firstNoteEl = discussionEl.querySelector('.note');
  const badge = new ImageBadge({
    actual: {
      x: position.x_axis,
      y: position.y_axis,
      width: position.width,
      height: position.height,
    },
    imageEl: imageFrameEl.querySelector('img'),
    noteId: firstNoteEl.id,
    discussionId: discussionEl.dataset.discussionId,
  });

  return badge;
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

// TODO: This transforms the value, doesn't necessarily have to transform into browser meta
export function generateBrowserMeta(imageEl, meta) {
  const { x, y, width, height } = meta;

  const browserImageWidth = imageEl.width;
  const browserImageHeight = imageEl.height;

  const widthRatio = browserImageWidth / width;
  const heightRatio = browserImageHeight / height;

  return {
    x: Math.round(x * widthRatio),
    y: Math.round(y * heightRatio),
    width: browserImageWidth,
    height: browserImageHeight,
  };
}
