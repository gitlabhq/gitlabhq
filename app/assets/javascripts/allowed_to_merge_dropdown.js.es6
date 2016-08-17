/*= require protected_branch_access_dropdown */

(global => {
  global.gl = global.gl || {};

  class allowedToMergeDropdown extends gl.ProtectedBranchAccessDropdown {
    fieldName(selectedItem) {
      let fieldName = '';
      let typeToName = {
        role: 'access_level',
        user: 'user_id',
      };
      let $input = this.$wrap.find(`input[name$="[${typeToName[selectedItem.type]}]"][value="${selectedItem.id}"]`);

      if ($input.length) {
        // If input exists return actual name
        fieldName = $input.attr('name');
      } else {
        // If not suggest a name
        fieldName = `protected_branch[merge_access_levels_attributes][${this.inputCount}][access_level]`; // Role by default

        if (selectedItem.type === 'user') {
          fieldName = `protected_branch[merge_access_levels_attributes][${this.inputCount}][user_id]`;
        }
      }

      return fieldName;
    }

    getActiveIds() {
      let selected = [];

      this.$wrap.find('input[name^="protected_branch[merge_access_levels_attributes]"]')
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
