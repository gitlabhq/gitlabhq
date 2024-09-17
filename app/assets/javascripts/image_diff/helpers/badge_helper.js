import { spriteIcon } from '~/lib/utils/common_utils';

export function createImageBadge(noteId, { x, y }, classNames = []) {
  const buttonEl = document.createElement('button');
  const classList = classNames.concat(['js-image-badge']);
  classList.forEach((className) => buttonEl.classList.add(className));
  buttonEl.setAttribute('type', 'button');
  buttonEl.setAttribute('disabled', true);
  buttonEl.dataset.noteId = noteId;
  buttonEl.style.left = `${x}px`;
  buttonEl.style.top = `${y}px`;

  return buttonEl;
}

export function addImageBadge(containerEl, { coordinate, badgeText, noteId }) {
  const buttonEl = createImageBadge(noteId, coordinate, [
    'gl-flex',
    'gl-items-center',
    'gl-justify-center',
    'gl-text-sm',
    'design-note-pin',
    'on-image',
    'gl-absolute',
  ]);
  buttonEl.textContent = badgeText;

  containerEl.appendChild(buttonEl);
}

export function addImageCommentBadge(containerEl, { coordinate, noteId }) {
  const buttonEl = createImageBadge(noteId, coordinate, ['image-comment-badge']);
  // eslint-disable-next-line no-unsanitized/property
  buttonEl.innerHTML = spriteIcon('image-comment-dark');

  containerEl.appendChild(buttonEl);
}

export function addAvatarBadge(el, event) {
  const { noteId, badgeNumber } = event.detail;

  // Add design pin to new comment
  const avatarBadgeEl = el.querySelector(`#${noteId} .design-note-pin`);
  avatarBadgeEl.textContent = badgeNumber;
  avatarBadgeEl.classList.remove('hidden');
}
