export function getTargetSelection(event) {
  const target = event.target;
  const container = target.parentElement;
  const x = event.offsetX ? (event.offsetX) : event.pageX - container.offsetLeft;
  const y = event.offsetY ? (event.offsetY) : event.pageY - container.offsetTop;

  const width = target.width;
  const height = target.height;

  const actualWidth = target.naturalWidth;
  const actualHeight = target.naturalHeight;

  const widthRatio = actualWidth / width;
  const heightRatio = actualHeight / height;

  // TODO: x, y contains the top left selection of the cursor
  // and does not equate to the pointy part of the comment image
  // Need to determine if we need to do offset calculations

  return {
    browser: {
      x,
      y,
      width,
      height,
    },
    actual: {
      x: x * widthRatio,
      y: y * heightRatio,
      width: actualWidth,
      height: actualHeight,
    },
  };
}

export function setLineCodeCoordinates(el, x, y) {
  const lineCode = el.dataset.lineCode;

  // TODO: Temporarily remove the trailing numbers that define the x and y coordinates
  // Until backend strips this out for us
  const lineCodeWithoutCoordinates = lineCode.match(/^(.*?)_/)[0];

  el.setAttribute('dataset-line-code', `${lineCodeWithoutCoordinates}${x}_${y}`);
}

export function setPositionDataAttribute(el, x, y) {
  const position = el.dataset.position;
  const positionObject = JSON.parse(position);
  positionObject.x_axis = x;
  positionObject.y_axis = y;
  positionObject.component_type = 'image';

  el.setAttribute('data-position', JSON.stringify(positionObject));
}

export function setCommentSelectionIndicator(containerEl, x, y) {
  const button = document.createElement('button');
  button.classList.add('btn-transparent', 'comment-selection');
  button.setAttribute('type', 'button');
  button.style.left = `${x}px`;
  button.style.top = `${y}px`;

  const image = document.createElement('img');
  image.classList.add('image-comment-dark');
  image.src = '/assets/icon_image_comment_dark.svg';
  image.alt = 'comment selection indicator';

  button.appendChild(image);
  containerEl.appendChild(button);
}
