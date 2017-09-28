export function addImageBadge(containerEl, { coordinate, badgeText, noteId }) {
  const { x, y } = coordinate;
  const buttonEl = document.createElement('button');
  buttonEl.classList.add('btn-transparent', 'badge', 'js-image-badge');
  buttonEl.setAttribute('type', 'button');
  buttonEl.dataset.noteId = noteId;
  buttonEl.innerText = badgeText;

  containerEl.appendChild(buttonEl);

  // TODO: We should use math to calculate the width so that we don't
  // have to do a reflow here but we can leave this here for now

  // Set button center to be the center of the clicked position
  const { width, height } = buttonEl.getBoundingClientRect();
  buttonEl.style.left = `${x - (width * 0.5)}px`;
  buttonEl.style.top = `${y - (height * 0.5)}px`;
}

export function imageBadgeOnClick(event) {
  event.stopPropagation();
  const badge = event.currentTarget;
  window.location.hash = badge.dataset.noteId;
}

// IMAGE BADGE END

export function addAvatarBadge(el, event) {
  const { noteId, badgeNumber } = event.detail;

  // Add badge to new comment
  const avatarBadgeEl = el.querySelector(`#${noteId} .badge`);
  avatarBadgeEl.innerText = badgeNumber;
  avatarBadgeEl.classList.remove('hidden');
}
