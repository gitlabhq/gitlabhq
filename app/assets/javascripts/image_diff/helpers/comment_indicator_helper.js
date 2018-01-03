export function addCommentIndicator(containerEl, { x, y }) {
  const buttonEl = document.createElement('button');
  buttonEl.classList.add('btn-transparent');
  buttonEl.classList.add('comment-indicator');
  buttonEl.setAttribute('type', 'button');
  buttonEl.style.left = `${x}px`;
  buttonEl.style.top = `${y}px`;

  buttonEl.innerHTML = gl.utils.spriteIcon('image-comment-dark');

  containerEl.appendChild(buttonEl);
}

export function removeCommentIndicator(imageFrameEl) {
  const commentIndicatorEl = imageFrameEl.querySelector('.comment-indicator');
  const imageEl = imageFrameEl.querySelector('img');
  const willRemove = !!commentIndicatorEl;
  let meta = {};

  if (willRemove) {
    meta = {
      x: parseInt(commentIndicatorEl.style.left, 10),
      y: parseInt(commentIndicatorEl.style.top, 10),
      image: {
        width: imageEl.width,
        height: imageEl.height,
      },
    };

    commentIndicatorEl.remove();
  }

  return Object.assign({}, meta, {
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
  const textareaEl = diffViewerEl.querySelector('.note-container .note-textarea');
  textareaEl.focus();
}
