/* global document */

import {
  COLLAPSE_BUTTON,
  COMMENT_BOX,
  COMMENT_BUTTON,
  FORM,
  FORM_CONTAINER,
  MR_ID,
  NOTE,
  NOTE_CONTAINER,
  REMEMBER_ITEM,
  REVIEW_CONTAINER,
  TOKEN_BOX,
} from '../shared';

// this style must be applied inline in a handful of components
/* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
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
const selectFormContainer = () => document.getElementById(FORM_CONTAINER);
const selectMrBox = () => document.getElementById(MR_ID);
const selectNote = () => document.getElementById(NOTE);
const selectNoteContainer = () => document.getElementById(NOTE_CONTAINER);
const selectRemember = () => document.getElementById(REMEMBER_ITEM);
const selectToken = () => document.getElementById(TOKEN_BOX);

export {
  buttonClearStyles,
  selectById,
  selectCollapseButton,
  selectContainer,
  selectCommentBox,
  selectCommentButton,
  selectForm,
  selectFormContainer,
  selectMrBox,
  selectNote,
  selectNoteContainer,
  selectRemember,
  selectToken,
};
