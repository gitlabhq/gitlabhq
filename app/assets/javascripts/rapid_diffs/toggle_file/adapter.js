import { COLLAPSE_FILE, EXPAND_FILE } from '~/rapid_diffs/events';

function getOppositeToggleButton(clicked) {
  const isOpened = clicked.dataset.opened;
  const parent = clicked.parentElement;

  return isOpened === ''
    ? parent.querySelector('button[data-closed]')
    : parent.querySelector('button[data-opened]');
}

function getElements(diffElement) {
  const fileBody = diffElement.querySelector('[data-file-body]');
  const button = diffElement.querySelector('[data-click="toggleFile"]');
  const oppositeToggleButton = getOppositeToggleButton(button);
  return { fileBody, oppositeToggleButton };
}

function collapse(fileBody = this.diffElement.querySelector('[data-file-body]')) {
  // eslint-disable-next-line no-param-reassign
  fileBody.hidden = true;
}

function expand(fileBody = this.diffElement.querySelector('[data-file-body]')) {
  // eslint-disable-next-line no-param-reassign
  fileBody.hidden = false;
}

export const ToggleFileAdapter = {
  clicks: {
    toggleFile() {
      const { fileBody, oppositeToggleButton } = getElements(this.diffElement);
      if (fileBody.hidden) {
        expand.call(this, fileBody);
      } else {
        collapse.call(this, fileBody);
      }
      oppositeToggleButton.focus();
    },
  },
  [EXPAND_FILE]() {
    expand.call(this);
  },
  [COLLAPSE_FILE]() {
    collapse.call(this);
  },
};
