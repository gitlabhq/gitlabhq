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
}

export function removeCommentIndicator(imageFrameEl) {
  const commentIndicatorEl = imageFrameEl.querySelector('.comment-indicator');
  const imageEl = imageFrameEl.querySelector('img');
  const willRemove = commentIndicatorEl !== null;
  let meta = {};

  if (willRemove) {
    meta = {
      x: parseInt(commentIndicatorEl.style.left.replace('px', ''), 10),
      y: parseInt(commentIndicatorEl.style.top.replace('px', ''), 10),
      image: {
        width: imageEl.width,
        height: imageEl.height,
      },
    };

    commentIndicatorEl.remove();
  }

  return Object.assign(meta, {
    removed: willRemove,
  });
}

export function showCommentIndicator(imageFrameEl, coordinate) {
  const { x, y } = coordinate;
  const commentIndicatorEl = imageFrameEl.querySelector('.comment-indicator');

  if (commentIndicatorEl) {
    commentIndicatorEl.style.left = `${x}px`;
    commentIndicatorEl.style.top = `${y}px`;
  } else {
    addCommentIndicator(imageFrameEl, coordinate);
  }
}

export function commentIndicatorOnClick(event) {
  // Prevent from triggering onAddImageDiffNote in notes.js
  event.stopPropagation();

  const buttonEl = event.currentTarget;
  const diffViewerEl = buttonEl.closest('.diff-viewer');
  const textareaEl = diffViewerEl.querySelector('.note-container form .note-textarea');
  textareaEl.focus();
}
