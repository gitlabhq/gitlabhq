import { initRemoveTag } from '../remove_tag';

document.addEventListener('DOMContentLoaded', () => {
  initRemoveTag({
    onDelete: path => {
      document
        .querySelector(`[data-path="${path}"]`)
        .closest('.js-tag-list')
        .remove();
    },
  });
});
