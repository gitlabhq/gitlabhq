import Autosize from 'autosize';

document.addEventListener('DOMContentLoaded', () => {
  const autosizeEls = document.querySelectorAll('.js-autosize');

  Autosize(autosizeEls);
  Autosize.update(autosizeEls);
});
