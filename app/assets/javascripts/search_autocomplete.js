(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.SearchAutocomplete = (function() {
    var KEYCODE;

    KEYCODE = {
      ESCAPE: 27,
      BACKSPACE: 8,
      ENTER: 13,
      UP: 38,
      DOWN: 40
    };

    function SearchAutocomplete(opts) {
      var ref, ref1, ref2, ref3, ref4;
      if (opts == null) {
        opts = {};
      }
      this.onSearchInputBlur = bind(this.onSearchInputBlur, this);
      this.onClearInputClick = bind(this.onClearInputClick, this);
      this.onSearchInputFocus = bind(this.onSearchInputFocus, this);
      this.onSearchInputClick = bind(this.onSearchInputClick, this);
      this.onSearchInputKeyUp = bind(this.onSearchInputKeyUp, this);
      this.onSearchInputKeyDown = bind(this.onSearchInputKeyDown, this);
      this.wrap = (ref = opts.wrap) != null ? ref : $('.search'), this.optsEl = (ref1 = opts.optsEl) != null ? ref1 : this.wrap.find('.search-autocomplete-opts'), this.autocompletePath = (ref2 = opts.autocompletePath) != null ? ref2 : this.optsEl.data('autocomplete-path'), this.projectId = (ref3 = opts.projectId) != null ? ref3 : this.optsEl.data('autocomplete-project-id') || '', this.projectRef = (ref4 = opts.projectRef) != null ? ref4 : this.optsEl.data('autocomplete-project-ref') || '';
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
      if (gon.current_user_id) {
        this.createAutocomplete();
      }
      this.searchInput.addClass('disabled');
      this.saveTextLength();
      this.bindEvents();
    }

    SearchAutocomplete.prototype.getElement = function(selector) {
      return this.wrap.find(selector);
    };

    SearchAutocomplete.prototype.saveOriginalState = function() {
      return this.originalState = this.serializeState();
    };

    SearchAutocomplete.prototype.saveTextLength = function() {
      return this.lastTextLength = this.searchInput.val().length;
    };

    SearchAutocomplete.prototype.createAutocomplete = function() {
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
    };

    SearchAutocomplete.prototype.getData = function(term, callback) {
      var _this, contents, jqXHR;
      _this = this;
      if (!term) {
        if (contents = this.getCategoryContents()) {
          this.searchInput.data('glDropdown').filter.options.callback(contents);
          this.enableAutocomplete();
        }
        return;
      }
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
        if (!response.length) {
          _this.disableAutocomplete();
          return;
        }
        data = [];
        firstCategory = true;
        for (i = 0, len = response.length; i < len; i++) {
          suggestion = response[i];
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
    };

    SearchAutocomplete.prototype.getCategoryContents = function() {
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
    };

    SearchAutocomplete.prototype.serializeState = function() {
      return {
        search_project_id: this.projectInputEl.val(),
        group_id: this.groupInputEl.val(),
        search_code: this.searchCodeInputEl.val(),
        repository_ref: this.repositoryInputEl.val(),
        scope: this.scopeInputEl.val(),
        _location: this.locationBadgeEl.text()
      };
    };

    SearchAutocomplete.prototype.bindEvents = function() {
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
    };

    SearchAutocomplete.prototype.enableAutocomplete = function() {
      var _this;
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

    SearchAutocomplete.prototype.onSearchInputKeyDown = function() {
      return this.saveTextLength();
    };

    SearchAutocomplete.prototype.onSearchInputKeyUp = function(e) {
      switch (e.keyCode) {
        case KEYCODE.BACKSPACE:
          if (this.lastTextLength === 0 && this.badgePresent()) {
            this.removeLocationBadge();
          }
          if (this.lastTextLength === 1) {
            this.disableAutocomplete();
          }
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
          if (this.searchInput.val() === '') {
            this.disableAutocomplete();
          } else {
            if (e.keyCode !== KEYCODE.ENTER) {
              this.enableAutocomplete();
            }
          }
      }
      this.wrap.toggleClass('has-value', !!e.target.value);
    };

    SearchAutocomplete.prototype.onSearchInputClick = function(e) {
      return e.stopImmediatePropagation();
    };

    SearchAutocomplete.prototype.onSearchInputFocus = function() {
      this.isFocused = true;
      this.wrap.addClass('search-active');
      if (this.getValue() === '') {
        return this.getData();
      }
    };

    SearchAutocomplete.prototype.getValue = function() {
      return this.searchInput.val();
    };

    SearchAutocomplete.prototype.onClearInputClick = function(e) {
      e.preventDefault();
      return this.searchInput.val('').focus();
    };

    SearchAutocomplete.prototype.onSearchInputBlur = function(e) {
      this.isFocused = false;
      this.wrap.removeClass('search-active');
      if (this.searchInput.val() === '') {
        return this.restoreOriginalState();
      }
    };

    SearchAutocomplete.prototype.addLocationBadge = function(item) {
      var badgeText, category, value;
      category = item.category != null ? item.category + ": " : '';
      value = item.value != null ? item.value : '';
      badgeText = "" + category + value;
      this.locationBadgeEl.text(badgeText).show();
      return this.wrap.addClass('has-location-badge');
    };

    SearchAutocomplete.prototype.hasLocationBadge = function() {
      return this.wrap.is('.has-location-badge');
    };

    SearchAutocomplete.prototype.restoreOriginalState = function() {
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
    };

    SearchAutocomplete.prototype.badgePresent = function() {
      return this.locationBadgeEl.length;
    };

    SearchAutocomplete.prototype.resetSearchState = function() {
      var i, input, inputs, len, results;
      inputs = Object.keys(this.originalState);
      results = [];
      for (i = 0, len = inputs.length; i < len; i++) {
        input = inputs[i];
        if (input === '_location') {
          break;
        }
        results.push(this.getElement("#" + input).val(''));
      }
      return results;
    };

    SearchAutocomplete.prototype.removeLocationBadge = function() {
      this.locationBadgeEl.hide();
      this.resetSearchState();
      this.wrap.removeClass('has-location-badge');
      return this.disableAutocomplete();
    };

    SearchAutocomplete.prototype.disableAutocomplete = function() {
      if (!this.searchInput.hasClass('disabled') && this.dropdown.hasClass('open')) {
        this.searchInput.addClass('disabled');
        this.dropdown.removeClass('open').trigger('hidden.bs.dropdown');
        this.restoreMenu();
      }
    };

    SearchAutocomplete.prototype.restoreMenu = function() {
      var html;
      html = "<ul> <li><a class='dropdown-menu-empty-link is-focused'>Loading...</a></li> </ul>";
      return this.dropdownContent.html(html);
    };

    SearchAutocomplete.prototype.onClick = function(item, $el, e) {
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

    return SearchAutocomplete;

  })();

}).call(this);
