import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';
import { FILTER_TYPE } from './constants';
import DropdownUtils from './dropdown_utils';
import FilteredSearchDropdownManager from './filtered_search_dropdown_manager';
import FilteredSearchVisualTokens from './filtered_search_visual_tokens';

const DATA_DROPDOWN_TRIGGER = 'data-dropdown-trigger';

export default class FilteredSearchDropdown {
  constructor({ droplab, dropdown, input, filter }) {
    this.droplab = droplab;
    this.hookId = input && input.id;
    this.input = input;
    this.filter = filter;
    this.dropdown = dropdown;
    this.loadingTemplate = `<div class="filter-dropdown-loading">
      ${loadingIconForLegacyJS().outerHTML}
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
    return this.droplab.hooks.filter((h) => h.id === this.hookId)[0] || null;
  }

  itemClicked(e, getValueFunction) {
    const { selected } = e.detail;
    if (selected.tagName === 'LI' && selected.innerHTML) {
      const { lastVisualToken: visualToken } =
        FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();
      const { tokenOperator } = DropdownUtils.getVisualTokenValues(visualToken);

      const dataValueSet = DropdownUtils.setDataValueIfSelected(
        this.filter,
        tokenOperator,
        selected,
      );

      if (!dataValueSet) {
        const value = getValueFunction(selected);
        FilteredSearchDropdownManager.addWordToInput({
          tokenName: this.filter,
          tokenOperator,
          tokenValue: value,
          clicked: true,
        });
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

    FilteredSearchDropdown.hideDropdownItemsforNotOperator(currentHook);

    if (forceShowList && currentHook && currentHook.list.hidden) {
      currentHook.list.show();
    }
  }

  render(forceRenderContent = false, forceShowList = false, hideNotEqual = false) {
    this.setAsDropdown();

    const currentHook = this.getCurrentHook();
    const firstTimeInitialized = currentHook === null;

    if (firstTimeInitialized || forceRenderContent) {
      this.renderContent(forceShowList, hideNotEqual);
    } else if (currentHook.list.list.id !== this.dropdown.id) {
      this.renderContent(forceShowList, hideNotEqual);
    }
  }

  dismissDropdown() {
    // Focusing on the input will dismiss dropdown
    // (default droplab functionality)
    this.input.focus();
  }

  dispatchInputEvent() {
    // Propagate input change to FilteredSearchDropdownManager
    // so that it can determine which dropdowns to open
    this.input.dispatchEvent(
      new CustomEvent('input', {
        bubbles: true,
        cancelable: true,
      }),
    );
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

  /**
   * Hide None & Any options from the current dropdown.
   * Hiding happens only for NOT operator.
   */
  static hideDropdownItemsforNotOperator(currentHook) {
    const lastOperator = FilteredSearchVisualTokens.getLastTokenOperator();

    if (lastOperator === '!=') {
      const { list: dropdownEl } = currentHook.list;

      let shouldHideDivider = true;

      // Iterate over all the static dropdown values,
      // then hide `None` and `Any` items.
      Array.from(dropdownEl.querySelectorAll('li[data-value]')).forEach((itemEl) => {
        const {
          dataset: { value },
        } = itemEl;

        if (value.toLowerCase() === FILTER_TYPE.none || value.toLowerCase() === FILTER_TYPE.any) {
          itemEl.classList.add('hidden');
        } else {
          // If we encountered any element other than None/Any, then
          // we shouldn't hide the divider
          shouldHideDivider = false;
        }
      });

      if (shouldHideDivider) {
        const divider = dropdownEl.querySelector('li.divider');
        if (divider) {
          divider.classList.add('hidden');
        }
      }
    }
  }
}
