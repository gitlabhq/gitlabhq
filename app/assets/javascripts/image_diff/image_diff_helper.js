export function getTargetSelection(event) {
  const container = event.currentTarget;
  const image = container.querySelector('img');
  const x = event.offsetX ? (event.offsetX) : event.pageX - container.offsetLeft;
  const y = event.offsetY ? (event.offsetY) : event.pageY - container.offsetTop;

  const width = image.width;
  const height = image.height;

  const actualWidth = image.naturalWidth;
  const actualHeight = image.naturalHeight;

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

export function setLineCodeCoordinates(el, coordinate) {
  const { x, y } = coordinate;
  const lineCode = el.dataset.lineCode;

  // TODO: Temporarily remove the trailing numbers that define the x and y coordinates
  // Until backend strips this out for us
  const lineCodeWithoutCoordinates = lineCode.match(/^(.*?)_/)[0];

  el.setAttribute('data-line-code', `${lineCodeWithoutCoordinates}${x}_${y}`);
}

export function setPositionDataAttribute(el, options) {
  const { x, y, width, height } = options;
  const position = el.dataset.position;
  const positionObject = JSON.parse(position);
  positionObject.x_axis = x;
  positionObject.y_axis = y;
  positionObject.width = width;
  positionObject.height = height;
  positionObject.position_type = 'image';

  el.setAttribute('data-position', JSON.stringify(positionObject));
}

export function addCommentIndicator(containerEl, coordinate) {
  const { x, y } = coordinate;
  const button = document.createElement('button');
  button.classList.add('btn-transparent', 'comment-indicator');
  button.setAttribute('type', 'button');
  button.style.left = `${x}px`;
  button.style.top = `${y}px`;

  const image = document.createElement('img');
  image.classList.add('image-comment-dark');
  image.src = '/assets/icon_image_comment_dark.svg';
  image.alt = 'comment indicator';

  button.appendChild(image);
  containerEl.appendChild(button);

  return button;
}

export function commentIndicatorOnClick(e) {
  // Prevent from triggering onAddImageDiffNote in notes.js
  e.stopPropagation();

  const button = e.currentTarget;
  const diffViewer = button.closest('.diff-viewer');
  const textarea = diffViewer.querySelector('.note-container form .note-textarea');
  textarea.focus();
}
