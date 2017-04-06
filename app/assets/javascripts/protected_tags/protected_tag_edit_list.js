import ProtectedTagEdit from './protected_tag_edit';

export default class ProtectedTagEditList {
  constructor() {
    this.$wrap = $('.protected-tags-list');
    this.protectedTagList = [];
    this.initEditForm();
  }

  initEditForm() {
    this.$wrap.find('.js-protected-tag-edit-form').each((i, el) => {
      this.protectedTagList[i] = new ProtectedTagEdit({
        $wrap: $(el),
      });
    });
  }
}
