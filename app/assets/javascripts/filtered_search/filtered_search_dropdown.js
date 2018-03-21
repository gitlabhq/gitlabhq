import DropdownUtils from './dropdown_utils';
import FilteredSearchDropdownManager from './filtered_search_dropdown_manager';

const DATA_DROPDOWN_TRIGGER = 'data-dropdown-trigger';

export default class FilteredSearchDropdown {
  constructor({ droplab, dropdown, input, filter }) {
    this.droplab = droplab;
    this.hookId = input && input.id;
    this.input = input;
    this.filter = filter;
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

    if (selected.tagName === 'LI' && selected.innerHTML) {
      const dataValueSet = DropdownUtils.setDataValueIfSelected(this.filter, selected);

      if (!dataValueSet) {
        const value = getValueFunction(selected);
        FilteredSearchDropdownManager.addWordToInput(this.filter, value, true);
      }

      this.resetFilters();
      this.dismissDropdown();
      this.dispatchInputEvent();
    }
  }

  setAsDropdown() {
    this.input.setAttribute(DATA_DROPDOWN_TRIGGER, `#${this.dropdown.id}`);
  }

  setOffset(offset = 0) {
    if (window.innerWidth > 480) {
      this.dropdown.style.left = `${offset}px`;
    } else {
      this.dropdown.style.left = '0px';
    }
  }

  renderContent(forceShowList = false) {
    const currentHook = this.getCurrentHook();
    if (forceShowList && currentHook && currentHook.list.hidden) {
      currentHook.list.show();
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
    this.input.dispatchEvent(new CustomEvent('input', {
      bubbles: true,
      cancelable: true,
    }));
  }

  dispatchFormSubmitEvent() {
    // dispatchEvent() is necessary as form.submit() does not
    // trigger event handlers
    this.input.form.dispatchEvent(new Event('submit'));
  }

  hideDropdown() {
    const currentHook = this.getCurrentHook();
    if (currentHook) {
      currentHook.list.hide();
    }
  }

  resetFilters() {
    const hook = this.getCurrentHook();

    if (hook) {
      const data = hook.list.data || [];

      if (!data) return;

      const results = data.map((o) => {
        const updated = o;
        updated.droplab_hidden = false;
        return updated;
      });
      hook.list.render(results);
    }
  }
}
