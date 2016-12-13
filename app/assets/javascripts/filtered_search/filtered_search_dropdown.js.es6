(() => {
  const DATA_DROPDOWN_TRIGGER = 'data-dropdown-trigger';

  class FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      this.droplab = droplab;
      this.hookId = input.getAttribute('data-id');
      this.input = input;
      this.dropdown = dropdown;
      this.loadingTemplate = `<div class="filter-dropdown-loading">
        <i class="fa fa-spinner fa-spin"></i>
      </div>`;
      this.bindEvents();
    }

    bindEvents() {
      this.itemClickedWrapper = this.itemClicked.bind(this);
      this.dropdown.addEventListener('click.dl', this.itemClickedWrapper);
    }

    unbindEvents() {
      this.dropdown.removeEventListener('click.dl', this.itemClickedWrapper);
    }

    getCurrentHook() {
      return this.droplab.hooks.filter(h => h.id === this.hookId)[0] || null;
    }

    itemClicked(e, getValueFunction) {
      const { selected } = e.detail;
      const dataValueSet = this.setDataValueIfSelected(selected);

      if (!dataValueSet) {
        const value = getValueFunction(selected);
        gl.FilteredSearchDropdownManager.addWordToInput(value);
      }

      this.dismissDropdown();
    }

    setAsDropdown() {
      this.input.setAttribute(DATA_DROPDOWN_TRIGGER, `#${this.dropdown.id}`);
    }

    setOffset(offset = 0) {
      this.dropdown.style.left = `${offset}px`;
    }

    setDataValueIfSelected(selected) {
      const dataValue = selected.getAttribute('data-value');

      if (dataValue) {
        gl.FilteredSearchDropdownManager.addWordToInput(dataValue);
      }

      // Return boolean based on whether it was set
      return dataValue !== null;
    }

    renderContent(forceShowList = false) {
      if (forceShowList && this.getCurrentHook().list.hidden) {
        this.getCurrentHook().list.show();
      }
    }

    render(forceRenderContent = false, forceShowList = false) {
      this.setAsDropdown();

      const currentHook = this.getCurrentHook();
      const firstTimeInitialized = currentHook === null;

      if (firstTimeInitialized || forceRenderContent) {
        this.renderContent(forceShowList);
      } else if (currentHook.list.list.id !== this.dropdown.id) {
        this.renderContent(forceShowList);
      }
    }

    dismissDropdown() {
      // Focusing on the input will dismiss dropdown
      // (default droplab functionality)
      this.input.focus();
    }

    dispatchInputEvent() {
      // Propogate input change to FilteredSearchDropdownManager
      // so that it can determine which dropdowns to open
      this.input.dispatchEvent(new Event('input'));
    }

    hideDropdown() {
      this.getCurrentHook().list.hide();
    }

    resetFilters() {
      const hook = this.getCurrentHook();
      const data = hook.list.data;
      const results = data.map((o) => {
        const updated = o;
        updated.droplab_hidden = false;
        return updated;
      });
      hook.list.render(results);
    }
  }

  window.gl = window.gl || {};
  gl.FilteredSearchDropdown = FilteredSearchDropdown;
})();
