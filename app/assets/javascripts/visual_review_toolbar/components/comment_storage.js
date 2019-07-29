import { selectCommentBox } from './utils';
import { sessionStorage } from '../shared';

const getSavedComment = () => sessionStorage.getItem('comment') || '';

const saveComment = () => {
  const currentComment = selectCommentBox();

  // This may be added to any view via top-level beforeunload listener
  // so let's skip if it does not apply
  if (currentComment && currentComment.value) {
    sessionStorage.setItem('comment', currentComment.value);
  }
};

const clearSavedComment = () => {
  sessionStorage.removeItem('comment');
};

export { getSavedComment, saveComment, clearSavedComment };
