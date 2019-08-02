import { selectCommentBox } from './utils';
import { sessionStorage, STORAGE_COMMENT } from '../shared';

const getSavedComment = () => sessionStorage.getItem(STORAGE_COMMENT) || '';

const saveComment = () => {
  const currentComment = selectCommentBox();

  // This may be added to any view via top-level beforeunload listener
  // so let's skip if it does not apply
  if (currentComment && currentComment.value) {
    sessionStorage.setItem(STORAGE_COMMENT, currentComment.value);
  }
};

const clearSavedComment = () => {
  sessionStorage.removeItem(STORAGE_COMMENT);
};

export { getSavedComment, saveComment, clearSavedComment };
