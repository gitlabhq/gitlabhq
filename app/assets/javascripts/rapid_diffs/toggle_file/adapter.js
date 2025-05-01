import { COLLAPSE_FILE, EXPAND_FILE } from '~/rapid_diffs/events';

function getOppositeToggleButton(clicked) {
  const isOpened = clicked.dataset.opened;
  const parent = clicked.parentElement;

  return isOpened === ''
    ? parent.querySelector('button[data-closed]')
    : parent.querySelector('button[data-opened]');
}

function collapse(root = this.diffElement) {
  // eslint-disable-next-line no-param-reassign
  root.dataset.collapsed = true;
  // eslint-disable-next-line no-param-reassign
  root.querySelector('[data-file-body]').hidden = true;
}

function expand(root = this.diffElement) {
  // eslint-disable-next-line no-param-reassign
  delete root.dataset.collapsed;
  // eslint-disable-next-line no-param-reassign
  root.querySelector('[data-file-body]').hidden = false;
}

function stopTransition(element) {
  element.style.transition = 'none';
  requestAnimationFrame(() => {
    element.style.transition = '';
  });
}

export const ToggleFileAdapter = {
  clicks: {
    toggleFile(event, button) {
      const collapsed = this.diffElement.dataset.collapsed === 'true';
      if (collapsed) {
        expand.call(this);
      } else {
        collapse.call(this);
      }
      const oppositeButton = getOppositeToggleButton(button);
      oppositeButton.focus();
      // a replaced button triggers another transition that we need to stop
      stopTransition(oppositeButton);
    },
  },
  [EXPAND_FILE]() {
    expand.call(this);
  },
  [COLLAPSE_FILE]() {
    collapse.call(this);
  },
};
