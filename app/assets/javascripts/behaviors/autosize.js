import Autosize from 'autosize';
import { waitForCSSLoaded } from '~/helpers/startup_css_helper';

document.addEventListener('DOMContentLoaded', () => {
  waitForCSSLoaded(() => {
    const autosizeEls = document.querySelectorAll('.js-autosize');

    Autosize(autosizeEls);
    Autosize.update(autosizeEls);

    autosizeEls.forEach(el => el.classList.add('js-autosize-initialized'));
  });
});
