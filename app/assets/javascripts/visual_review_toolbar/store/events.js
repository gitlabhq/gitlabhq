import {
  authorizeUser,
  logoutUser,
  postComment,
  toggleForm,
  COLLAPSE_BUTTON,
  COMMENT_BUTTON,
  LOGIN,
  LOGOUT,
} from '../components';

import { state } from './state';

const noop = () => {};

const eventLookup = ({ target: { id } }) => {
  switch (id) {
    case COLLAPSE_BUTTON:
      return toggleForm;
    case COMMENT_BUTTON:
      return postComment.bind(null, state);
    case LOGIN:
      return authorizeUser.bind(null, state);
    case LOGOUT:
      return logoutUser;
    default:
      return noop;
  }
};

const updateWindowSize = wind => {
  state.innerWidth = wind.innerWidth;
  state.innerHeight = wind.innerHeight;
};

export { eventLookup, updateWindowSize };
