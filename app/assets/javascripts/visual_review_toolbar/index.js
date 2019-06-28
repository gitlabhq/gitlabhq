import './styles/toolbar.css';

import { buttonAndForm, note, selectContainer, REVIEW_CONTAINER } from './components';
import { debounce, eventLookup, getInitialView, initializeState, updateWindowSize } from './store';

/*

  Welcome to the visual review toolbar files. A few useful notes:

  - These files build a static script that is served from our webpack
    assets folder. (https://gitlab.com/assets/webpack/visual_review_toolbar.js)

  - To compile this file, run `yarn webpack-vrt`.

  - Vue is not used in these files because we do not want to ask users to
    install another library at this time. It's all pure vanilla javascript.

*/

window.addEventListener('load', () => {
  initializeState(window, document);

  const mainContent = buttonAndForm(getInitialView(window));
  const container = document.createElement('div');
  container.setAttribute('id', REVIEW_CONTAINER);
  container.insertAdjacentHTML('beforeend', note);
  container.insertAdjacentHTML('beforeend', mainContent);

  document.body.insertBefore(container, document.body.firstChild);

  selectContainer().addEventListener('click', event => {
    eventLookup(event)();
  });

  window.addEventListener('resize', debounce(updateWindowSize.bind(null, window), 200));
});
