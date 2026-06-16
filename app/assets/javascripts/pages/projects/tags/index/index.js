import TagSortDropdown from '~/tags';
import initDeleteTagModal from '~/tags/init_delete_tag_modal';
import initIssuablePopovers from '~/issuable/popover';

initDeleteTagModal();
TagSortDropdown();
initIssuablePopovers(document.querySelectorAll('[data-reference-type="commit"]'));
