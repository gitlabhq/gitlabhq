/* eslint-disable no-return-assign, consistent-return, class-methods-use-this */

import $ from 'jquery';
import { escape, throttle } from 'lodash';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import { getIdenticonBackgroundClass, getIdenticonTitle } from '~/helpers/avatar_helper';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__, __, sprintf } from '~/locale';
import Tracking from '~/tracking';
import axios from './lib/utils/axios_utils';
import {
  isInGroupsPage,
  isInProjectPage,
  getGroupSlug,
  getProjectSlug,
  spriteIcon,
} from './lib/utils/common_utils';

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
  const $projectOptionsDataEl = $('.js-search-project-options');
  const $groupOptionsDataEl = $('.js-search-group-options');
  const $dashboardOptionsDataEl = $('.js-search-dashboard-options');

  if ($projectOptionsDataEl.length) {
    gl.projectOptions = gl.projectOptions || {};

    const projectPath = $projectOptionsDataEl.data('projectPath');

    gl.projectOptions[projectPath] = {
      name: $projectOptionsDataEl.data('name'),
      issuesPath: $projectOptionsDataEl.data('issuesPath'),
      issuesDisabled: $projectOptionsDataEl.data('issuesDisabled'),
      mrPath: $projectOptionsDataEl.data('mrPath'),
    };
  }

  if ($groupOptionsDataEl.length) {
    gl.groupOptions = gl.groupOptions || {};

    const groupPath = $groupOptionsDataEl.data('groupPath');

    gl.groupOptions[groupPath] = {
      name: $groupOptionsDataEl.data('name'),
      issuesPath: $groupOptionsDataEl.data('issuesPath'),
      mrPath: $groupOptionsDataEl.data('mrPath'),
    };
  }

  if ($dashboardOptionsDataEl.length) {
    gl.dashboardOptions = {
      name: s__('SearchAutocomplete|All GitLab'),
      issuesPath: $dashboardOptionsDataEl.data('issuesPath'),
      mrPath: $dashboardOptionsDataEl.data('mrPath'),
    };
  }
}

export class SearchAutocomplete {
  constructor({ wrap, optsEl, autocompletePath, projectId, projectRef } = {}) {
    setSearchOptions();
    this.bindEventContext();
    this.wrap = wrap || $('.search');
    this.optsEl = optsEl || this.wrap.find('.search-autocomplete-opts');
    this.autocompletePath = autocompletePath || this.optsEl.data('autocompletePath');
    this.projectId = projectId || this.optsEl.data('autocompleteProjectId') || '';
    this.projectRef = projectRef || this.optsEl.data('autocompleteProjectRef') || '';
    this.dropdown = this.wrap.find('.dropdown');
    this.dropdownToggle = this.wrap.find('.js-dropdown-search-toggle');
    this.dropdownMenu = this.dropdown.find('.dropdown-menu');
    this.dropdownContent = this.dropdown.find('.dropdown-content');
    this.scopeInputEl = this.getElement('#scope');
    this.searchInput = this.getElement('.search-input');
    this.projectInputEl = this.getElement('#search_project_id');
    this.groupInputEl = this.getElement('#group_id');
    this.searchCodeInputEl = this.getElement('#search_code');
    this.repositoryInputEl = this.getElement('#repository_ref');
    this.clearInput = this.getElement('.js-clear-input');
    this.scrollFadeInitialized = false;
    this.saveOriginalState();

    // Only when user is logged in
    if (gon.current_user_id) {
      this.createAutocomplete();
    }

    this.bindEvents();
    this.dropdownToggle.dropdown();
    this.searchInput.addClass('js-autocomplete-disabled');
  }

  // Finds an element inside wrapper element
  bindEventContext() {
    this.onSearchInputBlur = this.onSearchInputBlur.bind(this);
    this.onClearInputClick = this.onClearInputClick.bind(this);
    this.onSearchInputFocus = this.onSearchInputFocus.bind(this);
    this.onSearchInputKeyUp = this.onSearchInputKeyUp.bind(this);
    this.onSearchInputChange = this.onSearchInputChange.bind(this);
    this.setScrollFade = this.setScrollFade.bind(this);
  }
  getElement(selector) {
    return this.wrap.find(selector);
  }

  saveOriginalState() {
    return (this.originalState = this.serializeState());
  }

  createAutocomplete() {
    return initDeprecatedJQueryDropdown(this.searchInput, {
      filterInputBlur: false,
      filterable: true,
      filterRemote: true,
      highlight: true,
      icon: true,
      enterCallback: false,
      filterInput: 'input#search',
      search: {
        fields: ['text'],
      },
      id: this.getSearchText,
      data: this.getData.bind(this),
      selectable: true,
      clicked: this.onClick.bind(this),
      trackSuggestionClickedLabel: 'search_autocomplete_suggestion',
    });
  }

  getSearchText(selectedObject) {
    return selectedObject.id ? selectedObject.text : '';
  }

  getData(term, callback) {
    if (!term) {
      const contents = this.getCategoryContents();
      if (contents) {
        const deprecatedJQueryDropdownInstance = this.searchInput.data('deprecatedJQueryDropdown');

        if (deprecatedJQueryDropdownInstance) {
          deprecatedJQueryDropdownInstance.filter.options.callback(contents);
        }
        this.enableAutocomplete();
      }
      return;
    }

    // Prevent multiple ajax calls
    if (this.loadingSuggestions) {
      return;
    }

    this.loadingSuggestions = true;

    return axios
      .get(this.autocompletePath, {
        params: {
          project_id: this.projectId,
          project_ref: this.projectRef,
          term,
        },
      })
      .then((response) => {
        const options = this.scopedSearchOptions(term);

        // List results
        let lastCategory = null;
        for (let i = 0, len = response.data.length; i < len; i += 1) {
          const suggestion = response.data[i];
          // Add group header before list each group
          if (lastCategory !== suggestion.category) {
            options.push({ type: 'separator' });
            options.push({
              type: 'header',
              content: suggestion.category,
            });
            lastCategory = suggestion.category;
          }

          // Add the suggestion
          options.push({
            id: `${suggestion.category.toLowerCase()}-${suggestion.id}`,
            icon: this.getAvatar(suggestion),
            category: suggestion.category,
            text: suggestion.label,
            url: suggestion.url,
          });
        }

        callback(options);

        this.loadingSuggestions = false;
        this.highlightFirstRow();
        this.setScrollFade();
      })
      .catch(() => {
        this.loadingSuggestions = false;
      });
  }

  getCategoryContents() {
    const userName = gon.current_username;
    const { projectOptions, groupOptions, dashboardOptions } = gl;

    // Get options
    let options;
    if (isInProjectPage() && projectOptions) {
      options = projectOptions[getProjectSlug()];
    } else if (isInGroupsPage() && groupOptions) {
      options = groupOptions[getGroupSlug()];
    } else if (dashboardOptions) {
      options = dashboardOptions;
    }

    const { issuesPath, mrPath, name, issuesDisabled } = options;
    const baseItems = [];

    if (name) {
      baseItems.push({
        type: 'header',
        content: `${name}`,
      });
    }

    const issueItems = [
      {
        text: s__('SearchAutocomplete|Issues assigned to me'),
        url: `${issuesPath}/?assignee_username=${userName}`,
      },
      {
        text: s__("SearchAutocomplete|Issues I've created"),
        url: `${issuesPath}/?author_username=${userName}`,
      },
    ];
    const mergeRequestItems = [
      {
        text: s__('SearchAutocomplete|Merge requests assigned to me'),
        url: `${mrPath}/?assignee_username=${userName}`,
      },
      {
        text: s__("SearchAutocomplete|Merge requests that I'm a reviewer"),
        url: `${mrPath}/?reviewer_username=${userName}`,
      },
      {
        text: s__("SearchAutocomplete|Merge requests I've created"),
        url: `${mrPath}/?author_username=${userName}`,
      },
    ];

    let items;
    if (issuesDisabled) {
      items = baseItems.concat(mergeRequestItems);
    } else {
      items = baseItems.concat(...issueItems, ...mergeRequestItems);
    }
    return items;
  }

  // Add option to proceed with the search for each
  // scope that is currently available, namely:
  //
  // - Search in this project
  // - Search in this group (or project's group)
  // - Search in all GitLab
  scopedSearchOptions(term) {
    const icon = spriteIcon('search', 's16 inline-search-icon');
    const projectId = this.projectInputEl.val();
    const groupId = this.groupInputEl.val();
    const options = [];

    if (projectId) {
      const projectOptions = gl.projectOptions[getProjectSlug()];
      const url = groupId
        ? `${gon.relative_url_root}/search?search=${term}&project_id=${projectId}&group_id=${groupId}`
        : `${gon.relative_url_root}/search?search=${term}&project_id=${projectId}`;

      options.push({
        icon,
        text: term,
        template: sprintf(
          s__(`SearchAutocomplete|in project %{projectName}`),
          {
            projectName: `<i>${projectOptions.name}</i>`,
          },
          false,
        ),
        url,
      });
    }

    if (groupId) {
      const groupOptions = gl.groupOptions[getGroupSlug()];
      options.push({
        icon,
        text: term,
        template: sprintf(
          s__(`SearchAutocomplete|in group %{groupName}`),
          {
            groupName: `<i>${groupOptions.name}</i>`,
          },
          false,
        ),
        url: `${gon.relative_url_root}/search?search=${term}&group_id=${groupId}`,
      });
    }

    options.push({
      icon,
      text: term,
      template: s__('SearchAutocomplete|in all GitLab'),
      url: `${gon.relative_url_root}/search?search=${term}`,
    });

    return options;
  }

  serializeState() {
    return {
      // Search Criteria
      search_project_id: this.projectInputEl.val(),
      group_id: this.groupInputEl.val(),
      search_code: this.searchCodeInputEl.val(),
      repository_ref: this.repositoryInputEl.val(),
      scope: this.scopeInputEl.val(),
    };
  }

  bindEvents() {
    this.searchInput.on('input', this.onSearchInputChange);
    this.searchInput.on('keyup', this.onSearchInputKeyUp);
    this.searchInput.on('focus', this.onSearchInputFocus);
    this.searchInput.on('blur', this.onSearchInputBlur);
    this.clearInput.on('click', this.onClearInputClick);
    this.dropdownContent.on(
      'scroll',
      throttle(this.setScrollFade, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    );

    this.searchInput.on('click', (e) => {
      e.stopPropagation();
    });
  }

  enableAutocomplete() {
    this.setScrollFade();

    // No need to enable anything if user is not logged in
    if (!gon.current_user_id) {
      return;
    }

    // If the dropdown is closed, we'll open it
    if (!this.dropdown.hasClass('show')) {
      this.loadingSuggestions = false;
      this.dropdownToggle.dropdown('toggle');

      const trackEvent = 'click_search_bar';
      const trackCategory = undefined; // will be default set in event method

      Tracking.event(trackCategory, trackEvent, {
        label: 'main_navigation',
        property: 'navigation',
      });

      return this.searchInput.removeClass('js-autocomplete-disabled');
    }
  }

  onSearchInputChange() {
    this.enableAutocomplete();
  }

  onSearchInputKeyUp(e) {
    switch (e.keyCode) {
      case KEYCODE.ESCAPE:
        this.restoreOriginalState();
        break;
      case KEYCODE.ENTER:
        this.disableAutocomplete();
        break;
      default:
    }
    this.wrap.toggleClass('has-value', Boolean(e.target.value));
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
    this.wrap.toggleClass('has-value', Boolean(e.target.value));
    return this.searchInput.val('').focus();
  }

  onSearchInputBlur() {
    this.isFocused = false;
    this.wrap.removeClass('search-active');
    // If input is blank then restore state
    if (this.searchInput.val() === '') {
      this.restoreOriginalState();
    }
    this.dropdownMenu.removeClass('show');
  }

  restoreOriginalState() {
    const inputs = Object.keys(this.originalState);
    for (let i = 0, len = inputs.length; i < len; i += 1) {
      const input = inputs[i];
      this.getElement(`#${input}`).val(this.originalState[input]);
    }
  }

  resetSearchState() {
    const inputs = Object.keys(this.originalState);
    const results = [];
    for (let i = 0, len = inputs.length; i < len; i += 1) {
      const input = inputs[i];
      results.push(this.getElement(`#${input}`).val(''));
    }
    return results;
  }

  disableAutocomplete() {
    if (!this.searchInput.hasClass('js-autocomplete-disabled') && this.dropdown.hasClass('show')) {
      this.searchInput.addClass('js-autocomplete-disabled');
      this.dropdownToggle.dropdown('toggle');
      this.restoreMenu();
    }
  }

  restoreMenu() {
    const html = `<ul><li class="dropdown-menu-empty-item"><a>${__('Loading...')}</a></li></ul>`;
    return this.dropdownContent.html(html);
  }

  onClick(item, $el, e) {
    if (window.location.pathname.indexOf(item.url) !== -1) {
      if (!e.metaKey) e.preventDefault();
      /* eslint-disable-next-line @gitlab/require-i18n-strings */
      if (item.category === 'Projects') {
        this.projectInputEl.val(item.id);
      }
      // eslint-disable-next-line @gitlab/require-i18n-strings
      if (item.category === 'Groups') {
        this.groupInputEl.val(item.id);
      }
      $el.removeClass('is-active');
      this.disableAutocomplete();
      return this.searchInput.val('').focus();
    }
  }

  highlightFirstRow() {
    this.searchInput.data('deprecatedJQueryDropdown').highlightRowAtIndex(null, 0);
  }

  getAvatar(item) {
    if (!Object.hasOwnProperty.call(item, 'avatar_url')) {
      return false;
    }

    const { label, id } = item;
    const avatarUrl = item.avatar_url;
    const avatar = avatarUrl
      ? `<img class="search-item-avatar" src="${avatarUrl}" />`
      : `<div class="s16 avatar identicon ${getIdenticonBackgroundClass(id)}">${getIdenticonTitle(
          escape(label),
        )}</div>`;

    return avatar;
  }

  isScrolledUp() {
    const el = this.dropdownContent[0];
    const currentPosition = this.contentClientHeight + el.scrollTop;

    return currentPosition < this.maxPosition;
  }

  initScrollFade() {
    const el = this.dropdownContent[0];
    this.scrollFadeInitialized = true;

    this.contentClientHeight = el.clientHeight;
    this.maxPosition = el.scrollHeight;
    this.dropdownMenu.addClass('dropdown-content-faded-mask');
  }

  setScrollFade() {
    this.initScrollFade();

    this.dropdownMenu.toggleClass('fade-out', !this.isScrolledUp());
  }
}

export default function initSearchAutocomplete(opts) {
  return new SearchAutocomplete(opts);
}
