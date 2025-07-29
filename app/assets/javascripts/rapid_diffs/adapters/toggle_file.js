import { COLLAPSE_FILE, EXPAND_FILE, MOUNTED } from '~/rapid_diffs/adapter_events';

function getDetails(root) {
  return root.querySelector('[data-file-body]');
}

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
  getDetails(root).removeAttribute('open');
}

function expand(root = this.diffElement) {
  // eslint-disable-next-line no-param-reassign
  delete root.dataset.collapsed;
  getDetails(root).open = true;
}

function stopTransition(element) {
  element.style.transition = 'none';
  requestAnimationFrame(() => {
    element.style.transition = '';
  });
}

export const toggleFileAdapter = {
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
  [MOUNTED](onUnmounted) {
    const details = getDetails(this.diffElement);
    const handleToggle = () => {
      if (details.open) {
        expand.call(this);
      } else {
        collapse.call(this);
      }
    };
    details.addEventListener('toggle', handleToggle);
    onUnmounted(() => {
      details.removeEventListener('toggle', handleToggle);
    });
  },
};
