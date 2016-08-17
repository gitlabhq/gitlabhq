/*= require protected_branch_access_dropdown */

(global => {
  global.gl = global.gl || {};

  class allowedToMergeDropdown extends gl.ProtectedBranchAccessDropdown {
    fieldName(selectedItem) {
      // Role by default
      let fieldName = `protected_branch[merge_access_levels_attributes][${this.inputCount}][access_level]`;

      if (selectedItem.type === 'user') {
        fieldName = `protected_branch[merge_access_levels_attributes][${this.inputCount}][user_id]`;
      }

      return fieldName;
    }

    getActiveIds() {
      let selected = [];

      // Todo: Find a better way to get the wrap element of each dropdown
      let $wrap = this.$dropdown.parents().eq(1); // Please, don't judge me
      
      $wrap.find('input[name^="protected_branch[merge_access_levels_attributes]"]')
                        .map((i, el) => {
                          const $el = $(el);
                          selected.push({
                            id: parseInt($el.val()),
                            type: $el.data('type')
                          });
                        });

      return selected;
    }
  }

  global.gl.allowedToMergeDropdown = allowedToMergeDropdown;

})(window);
