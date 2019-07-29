import './styles/toolbar.css';

import { buttonAndForm, note, selectForm, selectContainer } from './components';
import { REVIEW_CONTAINER } from './shared';
import { eventLookup, getInitialView, initializeGlobalListeners, initializeState } from './store';

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

  const mainContent = buttonAndForm(getInitialView());
  const container = document.createElement('div');
  container.setAttribute('id', REVIEW_CONTAINER);
  container.insertAdjacentHTML('beforeend', note);
  container.insertAdjacentHTML('beforeend', mainContent);

  document.body.insertBefore(container, document.body.firstChild);

  selectContainer().addEventListener('click', event => {
    eventLookup(event.target.id)();
  });

  selectForm().addEventListener('submit', event => {
    // this is important to prevent the form from adding data
    // as URL params and inadvertently revealing secrets
    event.preventDefault();

    const id =
      event.target.querySelector('.gitlab-button-wrapper') &&
      event.target.querySelector('.gitlab-button-wrapper').getElementsByTagName('button')[0] &&
      event.target.querySelector('.gitlab-button-wrapper').getElementsByTagName('button')[0].id;

    // even if this is called with false, it's ok; it will get the default no-op
    eventLookup(id)();
  });

  initializeGlobalListeners();
});
