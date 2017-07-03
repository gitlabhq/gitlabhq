import autosize from 'vendor/autosize';

document.addEventListener('DOMContentLoaded', () => {
  const autosizeEls = document.querySelectorAll('.js-autosize');

  autosize(autosizeEls);
  autosize.update(autosizeEls);
});
