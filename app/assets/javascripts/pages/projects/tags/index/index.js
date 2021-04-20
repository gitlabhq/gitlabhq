import TagSortDropdown from '~/tags';
import { initRemoveTag } from '../remove_tag';

initRemoveTag({
  onDelete: (path) => {
    document.querySelector(`[data-path="${path}"]`).closest('.js-tag-list').remove();
  },
});
TagSortDropdown();
