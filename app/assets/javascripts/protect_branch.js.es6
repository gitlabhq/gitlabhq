class ProtectedBranchesAccessDropdown {
  constructor(options) {
    const { $dropdown, data, onSelect } = options;

    $dropdown.glDropdown({
      data: data,
      selectable: true,
      fieldName: $dropdown.data('field-name'),
      toggleLabel(item) {
        return item.text;
      },
      clicked(item, $el, e) {
        e.preventDefault();
        onSelect();
      }
    });
  }
}

class AllowedToMergeDropdowns {
  constructor (options) {
    const { $dropdowns, onSelect } = options;

    $dropdowns.each((i, el) => {
      new ProtectedBranchesAccessDropdown({
        $dropdown: $(el),
        data: gon.merge_access_levels,
        onSelect: onSelect
      });
    });
  }
}

class AllowedToPushSelects {
  constructor (options) {
    const { $dropdowns, onSelect } = options;

    $dropdowns.each((i, el) => {
      new ProtectedBranchesAccessDropdown({
        $dropdown: $(el),
        data: gon.push_access_levels,
        onSelect: onSelect
      });
    });
  }
}

class CreateProtectedBranch {
  constructor() {
    this.$wrap = this.$form = $('#new_protected_branch');
    this.buildDropdowns();
  }

  buildDropdowns() {
    // Allowed to Merge dropdowns
    new AllowedToMergeDropdowns({
      $dropdowns: this.$wrap.find('.js-allowed-to-merge'),
      onSelect: this.onSelect.bind(this)
    });

    // Allowed to Push dropdowns
    new AllowedToPushSelects({
      $dropdowns: this.$wrap.find('.js-allowed-to-push'),
      onSelect: this.onSelect.bind(this)
    });

    new ProtectedBranchSelects({
      $dropdowns: this.$wrap.find('.js-protected-branch-select'),
      onSelect: this.onSelect.bind(this)
    });
  }

  // This will run after clicked callback
  onSelect() {
    // Enable submit button
    const $branchInput = this.$wrap.find('input[name="protected_branch[name]"]');
    const $allowedToMergeInput = this.$wrap.find('input[name="protected_branch[merge_access_level_attributes][access_level]"]');
    const $allowedToPushInput = this.$wrap.find('input[name="protected_branch[push_access_level_attributes][access_level]"]');

    if ($branchInput.val() && $allowedToMergeInput.val() && $allowedToPushInput.val()){
      this.$form.find('[type="submit"]').removeAttr('disabled');
    }
  }
}
