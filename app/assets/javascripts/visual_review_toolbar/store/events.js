import {
  addMr,
  authorizeUser,
  changeSelectedMr,
  logoutUser,
  postComment,
  saveComment,
  toggleForm,
} from '../components';

import {
  CHANGE_MR_ID_BUTTON,
  COLLAPSE_BUTTON,
  COMMENT_BUTTON,
  LOGIN,
  LOGOUT,
  MR_ID_BUTTON,
} from '../shared';

import { state } from './state';
import debounce from './utils';

const noop = () => {};

// State needs to be bound here to be acted on
// because these are called by click events and
// as such are called with only the `event` object
const eventLookup = id => {
  switch (id) {
    case CHANGE_MR_ID_BUTTON:
      return () => {
        saveComment();
        changeSelectedMr(state);
      };
    case COLLAPSE_BUTTON:
      return toggleForm;
    case COMMENT_BUTTON:
      return postComment.bind(null, state);
    case LOGIN:
      return authorizeUser.bind(null, state);
    case LOGOUT:
      return () => {
        saveComment();
        logoutUser(state);
      };
    case MR_ID_BUTTON:
      return addMr.bind(null, state);
    default:
      return noop;
  }
};

const updateWindowSize = wind => {
  state.innerWidth = wind.innerWidth;
  state.innerHeight = wind.innerHeight;
};

const initializeGlobalListeners = () => {
  window.addEventListener('resize', debounce(updateWindowSize.bind(null, window), 200));
  window.addEventListener('beforeunload', event => {
    if (state.usingGracefulStorage) {
      // if there is no browser storage support, reloading will lose the comment; this way, the user will be warned
      // we assign the return value because it is required by Chrome see: https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onbeforeunload#Example,
      event.preventDefault();
      /* eslint-disable-next-line no-param-reassign */
      event.returnValue = '';
    }

    saveComment();
  });
};

export { eventLookup, initializeGlobalListeners };
