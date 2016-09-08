(global => {

  const KEYCODE = {
    ESCAPE: 27,
    BACKSPACE: 8,
    ENTER: 13,
    UP: 38,
    DOWN: 40
  };

  class SearchAutocomplete {
    constructor(opts = {}) {
      this.onSearchInputBlur = this.onSearchInputBlur.bind(this);
      this.onClearInputClick = this.onClearInputClick.bind(this);
      this.onSearchInputFocus = this.onSearchInputFocus.bind(this);
      this.onSearchInputClick = this.onSearchInputClick.bind(this);
      this.onSearchInputKeyUp = this.onSearchInputKeyUp.bind(this);
      this.onSearchInputKeyDown = this.onSearchInputKeyDown.bind(this);
      this.wrap = opts.wrap || $('.search');
      this.optsEl = opts.optsEl || this.wrap.find('.search-autocomplete-opts');
      this.autocompletePath = opts.autocompletePath || this.optsEl.data('autocomplete-path')
      this.projectId = opts.projectId || this.optsEl.data('autocomplete-project-id') || '';
      this.projectRef = opts.projectRef || this.optsEl.data('autocomplete-project-ref') || '';
      this.dropdown = this.wrap.find('.dropdown');
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
    }

    // Finds an element inside wrapper element
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
          fields: ['text']
        },
        data: this.getData.bind(this),
        selectable: true,
        clicked: this.onClick.bind(this)
      });
    }

    getData(term, callback) {
      var _this, contents, jqXHR;
      _this = this;
      if (!term) {
        if (contents = this.getCategoryContents()) {
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
      return jqXHR = $.get(this.autocompletePath, {
        project_id: this.projectId,
        project_ref: this.projectRef,
        term: term
      }, function(response) {
        var data, firstCategory, i, lastCategory, len, suggestion;
        // Hide dropdown menu if no suggestions returns
        if (!response.length) {
          _this.disableAutocomplete();
          return;
        }
        data = [];
        // List results
        firstCategory = true;
        for (i = 0, len = response.length; i < len; i++) {
          suggestion = response[i];
          // Add group header before list each group
          if (lastCategory !== suggestion.category) {
            if (!firstCategory) {
              data.push('separator');
            }
            if (firstCategory) {
              firstCategory = false;
            }
            data.push({
              header: suggestion.category
            });
            lastCategory = suggestion.category;
          }
          data.push({
            id: (suggestion.category.toLowerCase()) + "-" + suggestion.id,
            category: suggestion.category,
            text: suggestion.label,
            url: suggestion.url
          });
        }
        // Add option to proceed with the search
        if (data.length) {
          data.push('separator');
          data.push({
            text: "Result name contains \"" + term + "\"",
            url: "/search?search=" + term + "&project_id=" + (_this.projectInputEl.val()) + "&group_id=" + (_this.groupInputEl.val())
          });
        }
        return callback(data);
      }).always(function() {
        return _this.loadingSuggestions = false;
      });
    }

    getCategoryContents() {
      var dashboardOptions, groupOptions, issuesPath, items, mrPath, name, options, projectOptions, userId, utils;
      userId = gon.current_user_id;
      utils = gl.utils, projectOptions = gl.projectOptions, groupOptions = gl.groupOptions, dashboardOptions = gl.dashboardOptions;
      if (utils.isInGroupsPage() && groupOptions) {
        options = groupOptions[utils.getGroupSlug()];
      } else if (utils.isInProjectPage() && projectOptions) {
        options = projectOptions[utils.getProjectSlug()];
      } else if (dashboardOptions) {
        options = dashboardOptions;
      }
      issuesPath = options.issuesPath, mrPath = options.mrPath, name = options.name;
      items = [
        {
          header: "" + name
        }, {
          text: 'Issues assigned to me',
          url: issuesPath + "/?assignee_id=" + userId
        }, {
          text: "Issues I've created",
          url: issuesPath + "/?author_id=" + userId
        }, 'separator', {
          text: 'Merge requests assigned to me',
          url: mrPath + "/?assignee_id=" + userId
        }, {
          text: "Merge requests I've created",
          url: mrPath + "/?author_id=" + userId
        }
      ];
      if (!name) {
        items.splice(0, 1);
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
        _location: this.locationBadgeEl.text()
      };
    }

    bindEvents() {
      this.searchInput.on('keydown', this.onSearchInputKeyDown);
      this.searchInput.on('keyup', this.onSearchInputKeyUp);
      this.searchInput.on('click', this.onSearchInputClick);
      this.searchInput.on('focus', this.onSearchInputFocus);
      this.searchInput.on('blur', this.onSearchInputBlur);
      this.clearInput.on('click', this.onClearInputClick);
      return this.locationBadgeEl.on('click', (function(_this) {
        return function() {
          return _this.searchInput.focus();
        };
      })(this));
    }

    enableAutocomplete() {
      var _this;
      // No need to enable anything if user is not logged in
      if (!gon.current_user_id) {
        return;
      }
      if (!this.dropdown.hasClass('open')) {
        _this = this;
        this.loadingSuggestions = false;
        this.dropdown.addClass('open').trigger('shown.bs.dropdown');
        return this.searchInput.removeClass('disabled');
      }
    };

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

    // Avoid falsy value to be returned
    onSearchInputClick(e) {
      return e.stopImmediatePropagation();
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
    };

    restoreOriginalState() {
      var i, input, inputs, len;
      inputs = Object.keys(this.originalState);
      for (i = 0, len = inputs.length; i < len; i++) {
        input = inputs[i];
        this.getElement("#" + input).val(this.originalState[input]);
      }
      if (this.originalState._location === '') {
        return this.locationBadgeEl.hide();
      } else {
        return this.addLocationBadge({
          value: this.originalState._location
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
      for (i = 0, len = inputs.length; i < len; i++) {
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
      html = "<ul> <li><a class='dropdown-menu-empty-link is-focused'>Loading...</a></li> </ul>";
      return this.dropdownContent.html(html);
    };

    onClick(item, $el, e) {
      if (location.pathname.indexOf(item.url) !== -1) {
        e.preventDefault();
        if (!this.badgePresent) {
          if (item.category === 'Projects') {
            this.projectInputEl.val(item.id);
            this.addLocationBadge({
              value: 'This project'
            });
          }
          if (item.category === 'Groups') {
            this.groupInputEl.val(item.id);
            this.addLocationBadge({
              value: 'This group'
            });
          }
        }
        $el.removeClass('is-active');
        this.disableAutocomplete();
        return this.searchInput.val('').focus();
      }
    };

  }

  global.SearchAutocomplete = SearchAutocomplete;

  $(function() {
    var $projectOptionsDataEl = $('.js-search-project-options');
    var $groupOptionsDataEl = $('.js-search-group-options');
    var $dashboardOptionsDataEl = $('.js-search-dashboard-options');

    if ($projectOptionsDataEl.length) {
      gl.projectOptions = gl.projectOptions || {};

      var projectPath = $projectOptionsDataEl.data('project-path');

      gl.projectOptions[projectPath] = {
        name: $projectOptionsDataEl.data('name'),
        issuesPath: $projectOptionsDataEl.data('issues-path'),
        mrPath: $projectOptionsDataEl.data('mr-path')
      };
    }

    if ($groupOptionsDataEl.length) {
      gl.groupOptions = gl.groupOptions || {};

      var groupPath = $groupOptionsDataEl.data('group-path');

      gl.groupOptions[groupPath] = {
        name: $groupOptionsDataEl.data('name'),
        issuesPath: $groupOptionsDataEl.data('issues-path'),
        mrPath: $groupOptionsDataEl.data('mr-path')
      };
    }

    if ($dashboardOptionsDataEl.length) {
      gl.dashboardOptions = {
        issuesPath: $dashboardOptionsDataEl.data('issues-path'),
        mrPath: $dashboardOptionsDataEl.data('mr-path')
      };
    }
  });

})(window.gl || (window.gl = {}));
