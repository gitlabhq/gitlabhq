import $ from 'jquery';
import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import Project from '~/pages/projects/project';
import { visitUrl } from '~/lib/utils/url_utility';
import refreshCounts from './refresh_counts';

export default class Search {
  constructor() {
    this.searchInput = '.js-search-input';
    this.searchClear = '.js-search-clear';

    setHighlightClass(); // Code Highlighting
    this.eventListeners(); // Search Form Actions
    refreshCounts(); // Other Scope Tab Counts
    Project.initRefSwitcher(); // Code Search Branch Picker
  }

  eventListeners() {
    $(document).off('keyup', this.searchInput).on('keyup', this.searchInput, this.searchKeyUp);
    $(document)
      .off('click', this.searchClear)
      .on('click', this.searchClear, this.clearSearchField.bind(this));

    $('a.js-search-clear').off('click', this.clearSearchFilter).on('click', this.clearSearchFilter);
  }

  static submitSearch() {
    return $('.js-search-form').submit();
  }

  searchKeyUp() {
    const $input = $(this);
    if ($input.val() === '') {
      $('.js-search-clear').addClass('hidden');
    } else {
      $('.js-search-clear').removeClass('hidden');
    }
  }

  clearSearchField() {
    return $(this.searchInput).val('').trigger('keyup').focus();
  }

  // We need to manually follow the link on the anchors
  // that have this event bound, as their `click` default
  // behavior is prevented by the toggle logic.
  /* eslint-disable-next-line class-methods-use-this */
  clearSearchFilter(ev) {
    const $target = $(ev.currentTarget);

    visitUrl($target.href);
    ev.stopPropagation();
  }
}
