class ProtectedBranchEditList {
  constructor() {
    this.$wrap = $('.protected-branches-list');

    // Build edit forms
    this.$wrap.find('.js-protected-branch-edit-form').each((i, el) => {
      new ProtectedBranchEdit({
        $wrap: $(el)
      });
    });
  }
}
