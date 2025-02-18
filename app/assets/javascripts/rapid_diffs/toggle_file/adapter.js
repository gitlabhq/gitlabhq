function oppositeToggleButton(clicked) {
  const isOpened = clicked.dataset.opened;
  const parent = clicked.parentElement;

  return isOpened === ''
    ? parent.querySelector('button[data-closed]')
    : parent.querySelector('button[data-opened]');
}

export const ToggleFileAdapter = {
  clicks: {
    toggleFile(event) {
      const fileBody = this.diffElement.querySelector('[data-file-body]');
      const button = event.target.closest('button');
      const oppositeButton = oppositeToggleButton(button);

      fileBody.hidden = !fileBody.hidden;
      oppositeButton.focus();
    },
  },
};
