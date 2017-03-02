require('./filtered_search_dropdown');

/* global droplabFilter */

(() => {
  class DropdownHint extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input, filter) {
      super(droplab, dropdown, input, filter);
      this.config = {
        droplabFilter: {
          template: 'hint',
          filterFunction: gl.DropdownUtils.filterHint.bind(null, input),
        },
      };
    }

    itemClicked(e) {
      const { selected } = e.detail;

      if (selected.tagName === 'LI') {
        if (selected.hasAttribute('data-value')) {
          this.dismissDropdown();
        } else if (selected.getAttribute('data-action') === 'submit') {
          this.dismissDropdown();
          this.dispatchFormSubmitEvent();
        } else {
          const token = selected.querySelector('.js-filter-hint').innerText.trim();
          const tag = selected.querySelector('.js-filter-tag').innerText.trim();

          if (tag.length) {
            gl.FilteredSearchDropdownManager.addWordToInput(token.replace(':', ''));
          }
          this.dismissDropdown();
          this.dispatchInputEvent();
        }
      }
    }

    renderContent() {
      const dropdownData = [];

      [].forEach.call(this.input.parentElement.querySelectorAll('.dropdown-menu'), (dropdownMenu) => {
        const { icon, hint, tag } = dropdownMenu.dataset;
        if (icon && hint && tag) {
          dropdownData.push({
            icon: `fa-${icon}`,
            hint,
            tag: `&lt;${tag}&gt;`,
          });
        }
      });

      this.droplab.changeHookList(this.hookId, this.dropdown, [droplabFilter], this.config);
      this.droplab.setData(this.hookId, dropdownData);
    }

    init() {
      this.droplab.addHook(this.input, this.dropdown, [droplabFilter], this.config).init();
    }
  }

  window.gl = window.gl || {};
  gl.DropdownHint = DropdownHint;
})();
