/* eslint-disable no-return-assign, one-var, no-var, no-underscore-dangle, one-var-declaration-per-line, no-unused-vars, no-cond-assign, consistent-return, object-shorthand, prefer-arrow-callback, func-names, space-before-function-paren, prefer-template, quotes, class-methods-use-this, no-sequences, wrap-iife, no-lonely-if, no-else-return, no-param-reassign, vars-on-top, max-len */

import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import DropdownUtils from './filtered_search/dropdown_utils';
import { isInGroupsPage, isInProjectPage, getGroupSlug, getProjectSlug } from './lib/utils/common_utils';

/**
 * Search input in top navigation bar.
 * On click, opens a dropdown
 * As the user types it filters the results
 * When the user clicks `x` button it cleans the input and closes the dropdown.
 */

const KEYCODE = {
  ESCAPE: 27,
  BACKSPACE: 8,
  ENTER: 13,
  UP: 38,
  DOWN: 40,
};

function setSearchOptions() {
  var $projectOptionsDataEl = $('.js-search-project-options');
  var $groupOptionsDataEl = $('.js-search-group-options');
  var $dashboardOptionsDataEl = $('.js-search-dashboard-options');

  if ($projectOptionsDataEl.length) {
    gl.projectOptions = gl.projectOptions || {};

    var projectPath = $projectOptionsDataEl.data('projectPath');

    gl.projectOptions[projectPath] = {
      name: $projectOptionsDataEl.data('name'),
      issuesPath: $projectOptionsDataEl.data('issuesPath'),
      issuesDisabled: $projectOptionsDataEl.data('issuesDisabled'),
      mrPath: $projectOptionsDataEl.data('mrPath'),
    };
  }

  if ($groupOptionsDataEl.length) {
    gl.groupOptions = gl.groupOptions || {};

    var groupPath = $groupOptionsDataEl.data('groupPath');

    gl.groupOptions[groupPath] = {
      name: $groupOptionsDataEl.data('name'),
      issuesPath: $groupOptionsDataEl.data('issuesPath'),
      mrPath: $groupOptionsDataEl.data('mrPath'),
    };
  }

  if ($dashboardOptionsDataEl.length) {
    gl.dashboardOptions = {
      issuesPath: $dashboardOptionsDataEl.data('issuesPath'),
      mrPath: $dashboardOptionsDataEl.data('mrPath'),
    };
  }
}

export default class SearchAutocomplete {
  constructor({ wrap, optsEl, autocompletePath, projectId, projectRef } = {}) {
    setSearchOptions();
    this.bindEventContext();
    this.wrap = wrap || $('.search');
    this.optsEl = optsEl || this.wrap.find('.search-autocomplete-opts');
    this.autocompletePath = autocompletePath || this.optsEl.data('autocompletePath');
    this.projectId = projectId || (this.optsEl.data('autocompleteProjectId') || '');
    this.projectRef = projectRef || (this.optsEl.data('autocompleteProjectRef') || '');
    this.dropdown = this.wrap.find('.dropdown');
    this.dropdownToggle = this.wrap.find('.js-dropdown-search-toggle');
    this.dropdownContent = this.dropdown.find('.dropdown-content');
    this.locationBadgeEl = this.getElement('.location-badge');
    this.scopeInputEl = this.getElement('#scope');
    this.searchInput = this.getElement('.search-input');
    this.projectInputEl = this.getElement('#search_project_id');
    this.groupInputEl = this.getElement('#group_id');
    this.searchCodeInputEl = this.getElement('#search_code');
    this.repositoryInputEl = this.getElement('#repository_ref');
    this.clearInput = this.getElement('.js-clear-input');
    this.saveOriginalState();

    // Only when user is logged in
    if (gon.current_user_id) {
      this.createAutocomplete();
    }

    this.searchInput.addClass('disabled');
    this.saveTextLength();
    this.bindEvents();
    this.dropdownToggle.dropdown();
  }

  // Finds an element inside wrapper element
  bindEventContext() {
    this.onSearchInputBlur = this.onSearchInputBlur.bind(this);
    this.onClearInputClick = this.onClearInputClick.bind(this);
    this.onSearchInputFocus = this.onSearchInputFocus.bind(this);
    this.onSearchInputKeyUp = this.onSearchInputKeyUp.bind(this);
    this.onSearchInputKeyDown = this.onSearchInputKeyDown.bind(this);
  }
  getElement(selector) {
    return this.wrap.find(selector);
  }

  saveOriginalState() {
    return this.originalState = this.serializeState();
  }

  saveTextLength() {
    return this.lastTextLength = this.searchInput.val().length;
  }

  createAutocomplete() {
    return this.searchInput.glDropdown({
      filterInputBlur: false,
      filterable: true,
      filterRemote: true,
      highlight: true,
      enterCallback: false,
      filterInput: 'input#search',
      search: {
        fields: ['text'],
      },
      id: this.getSearchText,
      data: this.getData.bind(this),
      selectable: true,
      clicked: this.onClick.bind(this),
    });
  }

  getSearchText(selectedObject, el) {
    return selectedObject.id ? selectedObject.text : '';
  }

  getData(term, callback) {
    if (!term) {
      const contents = this.getCategoryContents();
      if (contents) {
        this.searchInput.data('glDropdown').filter.options.callback(contents);
        this.enableAutocomplete();
      }
      return;
    }

    // Prevent multiple ajax calls
    if (this.loadingSuggestions) {
      return;
    }

    this.loadingSuggestions = true;

    return axios.get(this.autocompletePath, {
      params: {
        project_id: this.projectId,
        project_ref: this.projectRef,
        term: term,
      },
    }).then((response) => {
      // Hide dropdown menu if no suggestions returns
      if (!response.data.length) {
        this.disableAutocomplete();
        return;
      }

      const data = [];
      // List results
      let firstCategory = true;
      let lastCategory;
      for (let i = 0, len = response.data.length; i < len; i += 1) {
        const suggestion = response.data[i];
        // Add group header before list each group
        if (lastCategory !== suggestion.category) {
          if (!firstCategory) {
            data.push('separator');
          }
          if (firstCategory) {
            firstCategory = false;
          }
          data.push({
            header: suggestion.category,
          });
          lastCategory = suggestion.category;
        }
        data.push({
          id: `${suggestion.category.toLowerCase()}-${suggestion.id}`,
          category: suggestion.category,
          text: suggestion.label,
          url: suggestion.url,
        });
      }
      // Add option to proceed with the search
      if (data.length) {
        data.push('separator');
        data.push({
          text: `Result name contains "${term}"`,
          url: `/search?search=${term}&project_id=${this.projectInputEl.val()}&group_id=${this.groupInputEl.val()}`,
        });
      }

      callback(data);

      this.loadingSuggestions = false;
    }).catch(() => {
      this.loadingSuggestions = false;
    });
  }

  getCategoryContents() {
    const userId = gon.current_user_id;
    const userName = gon.current_username;
    const { projectOptions, groupOptions, dashboardOptions } = gl;

    // Get options
    let options;
    if (isInGroupsPage() && groupOptions) {
      options = groupOptions[getGroupSlug()];
    } else if (isInProjectPage() && projectOptions) {
      options = projectOptions[getProjectSlug()];
    } else if (dashboardOptions) {
      options = dashboardOptions;
    }

    const { issuesPath, mrPath, name, issuesDisabled } = options;
    const baseItems = [];

    if (name) {
      baseItems.push({
        header: `${name}`,
      });
    }

    const issueItems = [
      {
        text: 'Issues assigned to me',
        url: `${issuesPath}/?assignee_id=${userId}`,
      },
      {
        text: "Issues I've created",
        url: `${issuesPath}/?author_id=${userId}`,
      },
    ];
    const mergeRequestItems = [
      {
        text: 'Merge requests assigned to me',
        url: `${mrPath}/?assignee_id=${userId}`,
      },
      {
        text: "Merge requests I've created",
        url: `${mrPath}/?author_id=${userId}`,
      },
    ];

    let items;
    if (issuesDisabled) {
      items = baseItems.concat(mergeRequestItems);
    } else {
      items = baseItems.concat(...issueItems, 'separator', ...mergeRequestItems);
    }
    return items;
  }

  serializeState() {
    return {
      // Search Criteria
      search_project_id: this.projectInputEl.val(),
      group_id: this.groupInputEl.val(),
      search_code: this.searchCodeInputEl.val(),
      repository_ref: this.repositoryInputEl.val(),
      scope: this.scopeInputEl.val(),
      // Location badge
      _location: this.locationBadgeEl.text(),
    };
  }

  bindEvents() {
    this.searchInput.on('keydown', this.onSearchInputKeyDown);
    this.searchInput.on('keyup', this.onSearchInputKeyUp);
    this.searchInput.on('focus', this.onSearchInputFocus);
    this.searchInput.on('blur', this.onSearchInputBlur);
    this.clearInput.on('click', this.onClearInputClick);
    this.locationBadgeEl.on('click', () => this.searchInput.focus());
  }

  enableAutocomplete() {
    // No need to enable anything if user is not logged in
    if (!gon.current_user_id) {
      return;
    }

    // If the dropdown is closed, we'll open it
    if (!this.dropdown.hasClass('open')) {
      this.loadingSuggestions = false;
      this.dropdownToggle.dropdown('toggle');
      return this.searchInput.removeClass('disabled');
    }
  }

  // Saves last length of the entered text
  onSearchInputKeyDown() {
    return this.saveTextLength();
  }

  onSearchInputKeyUp(e) {
    switch (e.keyCode) {
      case KEYCODE.BACKSPACE:
        // when trying to remove the location badge
        if (this.lastTextLength === 0 && this.badgePresent()) {
          this.removeLocationBadge();
        }
        // When removing the last character and no badge is present
        if (this.lastTextLength === 1) {
          this.disableAutocomplete();
        }
        // When removing any character from existin value
        if (this.lastTextLength > 1) {
          this.enableAutocomplete();
        }
        break;
      case KEYCODE.ESCAPE:
        this.restoreOriginalState();
        break;
      case KEYCODE.ENTER:
        this.disableAutocomplete();
        break;
      case KEYCODE.UP:
      case KEYCODE.DOWN:
        return;
      default:
        // Handle the case when deleting the input value other than backspace
        // e.g. Pressing ctrl + backspace or ctrl + x
        if (this.searchInput.val() === '') {
          this.disableAutocomplete();
        } else {
          // We should display the menu only when input is not empty
          if (e.keyCode !== KEYCODE.ENTER) {
            this.enableAutocomplete();
          }
        }
    }
    this.wrap.toggleClass('has-value', !!e.target.value);
  }

  onSearchInputFocus() {
    this.isFocused = true;
    this.wrap.addClass('search-active');
    if (this.getValue() === '') {
      return this.getData();
    }
  }

  getValue() {
    return this.searchInput.val();
  }

  onClearInputClick(e) {
    e.preventDefault();
    this.wrap.toggleClass('has-value', !!e.target.value);
    return this.searchInput.val('').focus();
  }

  onSearchInputBlur(e) {
    this.isFocused = false;
    this.wrap.removeClass('search-active');
    // If input is blank then restore state
    if (this.searchInput.val() === '') {
      return this.restoreOriginalState();
    }
  }

  addLocationBadge(item) {
    var badgeText, category, value;
    category = item.category != null ? item.category + ": " : '';
    value = item.value != null ? item.value : '';
    badgeText = "" + category + value;
    this.locationBadgeEl.text(badgeText).show();
    return this.wrap.addClass('has-location-badge');
  }

  hasLocationBadge() {
    return this.wrap.is('.has-location-badge');
  }

  restoreOriginalState() {
    var i, input, inputs, len;
    inputs = Object.keys(this.originalState);
    for (i = 0, len = inputs.length; i < len; i += 1) {
      input = inputs[i];
      this.getElement("#" + input).val(this.originalState[input]);
    }
    if (this.originalState._location === '') {
      return this.locationBadgeEl.hide();
    } else {
      return this.addLocationBadge({
        value: this.originalState._location,
      });
    }
  }

  badgePresent() {
    return this.locationBadgeEl.length;
  }

  resetSearchState() {
    var i, input, inputs, len, results;
    inputs = Object.keys(this.originalState);
    results = [];
    for (i = 0, len = inputs.length; i < len; i += 1) {
      input = inputs[i];
      // _location isnt a input
      if (input === '_location') {
        break;
      }
      results.push(this.getElement("#" + input).val(''));
    }
    return results;
  }

  removeLocationBadge() {
    this.locationBadgeEl.hide();
    this.resetSearchState();
    this.wrap.removeClass('has-location-badge');
    return this.disableAutocomplete();
  }

  disableAutocomplete() {
    if (!this.searchInput.hasClass('disabled') && this.dropdown.hasClass('open')) {
      this.searchInput.addClass('disabled');
      this.dropdown.removeClass('open').trigger('hidden.bs.dropdown');
      this.restoreMenu();
    }
  }

  restoreMenu() {
    var html;
    html = '<ul><li class="dropdown-menu-empty-item"><a>Loading...</a></li></ul>';
    return this.dropdownContent.html(html);
  }

  onClick(item, $el, e) {
    if (location.pathname.indexOf(item.url) !== -1) {
      if (!e.metaKey) e.preventDefault();
      if (!this.badgePresent) {
        if (item.category === 'Projects') {
          this.projectInputEl.val(item.id);
          this.addLocationBadge({
            value: 'This project',
          });
        }
        if (item.category === 'Groups') {
          this.groupInputEl.val(item.id);
          this.addLocationBadge({
            value: 'This group',
          });
        }
      }
      $el.removeClass('is-active');
      this.disableAutocomplete();
      return this.searchInput.val('').focus();
    }
  }
}
