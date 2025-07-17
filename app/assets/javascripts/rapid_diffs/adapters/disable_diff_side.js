import { INVISIBLE, VISIBLE } from '~/rapid_diffs/adapter_events';

const opposingSides = {
  old: 'new',
  new: 'old',
};

function disableDiffsSideHandler(e) {
  const target = e.target.closest('[data-position]');
  if (!target) return;
  const { position } = target.dataset;
  this.diffElement.dataset.disableDiffSide = opposingSides[position];
}

const getBody = (diffElement) => diffElement.querySelector('[data-file-body]');

export const disableDiffSideAdapter = {
  [VISIBLE]() {
    this.sink.disableDiffsSideHandler = disableDiffsSideHandler.bind(this);
    getBody(this.diffElement).addEventListener('mousedown', this.sink.disableDiffsSideHandler);
  },
  [INVISIBLE]() {
    if (this.sink.disableDiffsSideHandler) {
      getBody(this.diffElement).removeEventListener('mousedown', this.sink.disableDiffsSideHandler);
    }
  },
};
