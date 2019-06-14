/* global document */

import {
  COLLAPSE_BUTTON,
  COMMENT_BOX,
  COMMENT_BUTTON,
  FORM,
  NOTE,
  REMEMBER_TOKEN,
  REVIEW_CONTAINER,
  TOKEN_BOX,
} from './constants';

// this style must be applied inline in a handful of components
const buttonClearStyles = `
  -webkit-appearance: none;
`;

// selector functions to abstract out a little
const selectById = id => document.getElementById(id);
const selectCollapseButton = () => document.getElementById(COLLAPSE_BUTTON);
const selectCommentBox = () => document.getElementById(COMMENT_BOX);
const selectCommentButton = () => document.getElementById(COMMENT_BUTTON);
const selectContainer = () => document.getElementById(REVIEW_CONTAINER);
const selectForm = () => document.getElementById(FORM);
const selectNote = () => document.getElementById(NOTE);
const selectRemember = () => document.getElementById(REMEMBER_TOKEN);
const selectToken = () => document.getElementById(TOKEN_BOX);

export {
  buttonClearStyles,
  selectById,
  selectCollapseButton,
  selectContainer,
  selectCommentBox,
  selectCommentButton,
  selectForm,
  selectNote,
  selectRemember,
  selectToken,
};
