(function() {
  var GitLabDropdown, GitLabDropdownFilter, GitLabDropdownRemote,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  GitLabDropdownFilter = (function() {
    var ARROW_KEY_CODES, BLUR_KEYCODES, HAS_VALUE_CLASS;

    BLUR_KEYCODES = [27, 40];

    ARROW_KEY_CODES = [38, 40];

    HAS_VALUE_CLASS = "has-value";

    function GitLabDropdownFilter(input, options) {
      var $clearButton, $inputContainer, ref, timeout;
      this.input = input;
      this.options = options;
      this.filterInputBlur = (ref = this.options.filterInputBlur) != null ? ref : true;
      $inputContainer = this.input.parent();
      $clearButton = $inputContainer.find('.js-dropdown-input-clear');
      this.indeterminateIds = [];
      $clearButton.on('click', (function(_this) {
        // Clear click
        return function(e) {
          e.preventDefault();
          e.stopPropagation();
          return _this.input.val('').trigger('input').focus();
        };
      })(this));
      // Key events
      timeout = "";
      this.input
        .on('keydown', function (e) {
          var keyCode = e.which;
          if (keyCode === 13 && !options.elIsInput) {
            e.preventDefault()
          }
        })
        .on('input', function() {
          if (this.input.val() !== "" && !$inputContainer.hasClass(HAS_VALUE_CLASS)) {
            $inputContainer.addClass(HAS_VALUE_CLASS);
          } else if (this.input.val() === "" && $inputContainer.hasClass(HAS_VALUE_CLASS)) {
            $inputContainer.removeClass(HAS_VALUE_CLASS);
          }
          // Only filter asynchronously only if option remote is set
          if (this.options.remote) {
            clearTimeout(timeout);
            return timeout = setTimeout(function() {
              return this.options.query(this.input.val(), function(data) {
                return this.options.callback(data);
              }.bind(this));
            }.bind(this), 250);
          } else {
            return this.filter(this.input.val());
          }
        }.bind(this));
    }

    GitLabDropdownFilter.prototype.shouldBlur = function(keyCode) {
      return BLUR_KEYCODES.indexOf(keyCode) >= 0;
    };

    GitLabDropdownFilter.prototype.filter = function(search_text) {
      var data, elements, group, key, results, tmp;
      if (this.options.onFilter) {
        this.options.onFilter(search_text);
      }
      data = this.options.data();
      if ((data != null) && !this.options.filterByText) {
        results = data;
        if (search_text !== '') {
          // When data is an array of objects therefore [object Array] e.g.
          // [
          //   { prop: 'foo' },
          //   { prop: 'baz' }
          // ]
          if (_.isArray(data)) {
            results = fuzzaldrinPlus.filter(data, search_text, {
              key: this.options.keys
            });
          } else {
            // If data is grouped therefore an [object Object]. e.g.
            // {
            //   groupName1: [
            //     { prop: 'foo' },
            //     { prop: 'baz' }
            //   ],
            //   groupName2: [
            //     { prop: 'abc' },
            //     { prop: 'def' }
            //   ]
            // }
            if (gl.utils.isObject(data)) {
              results = {};
              for (key in data) {
                group = data[key];
                tmp = fuzzaldrinPlus.filter(group, search_text, {
                  key: this.options.keys
                });
                if (tmp.length) {
                  results[key] = tmp.map(function(item) {
                    return item;
                  });
                }
              }
            }
          }
        }
        return this.options.callback(results);
      } else {
        elements = this.options.elements();
        if (search_text) {
          return elements.each(function() {
            var $el, matches;
            $el = $(this);
            matches = fuzzaldrinPlus.match($el.text().trim(), search_text);
            if (!$el.is('.dropdown-header')) {
              if (matches.length) {
                return $el.show().removeClass('option-hidden');
              } else {
                return $el.hide().addClass('option-hidden');
              }
            }
          });
        } else {
          return elements.show().removeClass('option-hidden');
        }
      }
    };

    return GitLabDropdownFilter;

  })();

  GitLabDropdownRemote = (function() {
    function GitLabDropdownRemote(dataEndpoint, options) {
      this.dataEndpoint = dataEndpoint;
      this.options = options;
    }

    GitLabDropdownRemote.prototype.execute = function() {
      if (typeof this.dataEndpoint === "string") {
        return this.fetchData();
      } else if (typeof this.dataEndpoint === "function") {
        if (this.options.beforeSend) {
          this.options.beforeSend();
        }
        return this.dataEndpoint("", (function(_this) {
          // Fetch the data by calling the data funcfion
          return function(data) {
            if (_this.options.success) {
              _this.options.success(data);
            }
            if (_this.options.beforeSend) {
              return _this.options.beforeSend();
            }
          };
        })(this));
      }
    };

    GitLabDropdownRemote.prototype.fetchData = function() {
      return $.ajax({
        url: this.dataEndpoint,
        dataType: this.options.dataType,
        beforeSend: (function(_this) {
          return function() {
            if (_this.options.beforeSend) {
              return _this.options.beforeSend();
            }
          };
        })(this),
        success: (function(_this) {
          return function(data) {
            if (_this.options.success) {
              return _this.options.success(data);
            }
          };
        })(this)
      });
    // Fetch the data through ajax if the data is a string
    };

    return GitLabDropdownRemote;

  })();

  GitLabDropdown = (function() {
    var ACTIVE_CLASS, FILTER_INPUT, INDETERMINATE_CLASS, LOADING_CLASS, PAGE_TWO_CLASS, NON_SELECTABLE_CLASSES, SELECTABLE_CLASSES, currentIndex;

    LOADING_CLASS = "is-loading";

    PAGE_TWO_CLASS = "is-page-two";

    ACTIVE_CLASS = "is-active";

    INDETERMINATE_CLASS = "is-indeterminate";

    currentIndex = -1;

    NON_SELECTABLE_CLASSES = '.divider, .separator, .dropdown-header, .dropdown-menu-empty-link';

    SELECTABLE_CLASSES = ".dropdown-content li:not(" + NON_SELECTABLE_CLASSES + ", .option-hidden)";

    CURSOR_SELECT_SCROLL_PADDING = 5

    FILTER_INPUT = '.dropdown-input .dropdown-input-field';

    function GitLabDropdown(el1, options) {
      var ref, ref1, ref2, ref3, searchFields, selector, self;
      this.el = el1;
      this.options = options;
      this.updateLabel = bind(this.updateLabel, this);
      this.hidden = bind(this.hidden, this);
      this.opened = bind(this.opened, this);
      this.shouldPropagate = bind(this.shouldPropagate, this);
      self = this;
      selector = $(this.el).data("target");
      this.dropdown = selector != null ? $(selector) : $(this.el).parent();
      // Set Defaults
      ref = this.options, this.filterInput = (ref1 = ref.filterInput) != null ? ref1 : this.getElement(FILTER_INPUT), this.highlight = (ref2 = ref.highlight) != null ? ref2 : false, this.filterInputBlur = (ref3 = ref.filterInputBlur) != null ? ref3 : true;
      // If no input is passed create a default one
      self = this;
      // If selector was passed
      if (_.isString(this.filterInput)) {
        this.filterInput = this.getElement(this.filterInput);
      }
      searchFields = this.options.search ? this.options.search.fields : [];
      if (this.options.data) {
        // If we provided data
        // data could be an array of objects or a group of arrays
        if (_.isObject(this.options.data) && !_.isFunction(this.options.data)) {
          this.fullData = this.options.data;
          currentIndex = -1;
          this.parseData(this.options.data);
        } else {
          this.remote = new GitLabDropdownRemote(this.options.data, {
            dataType: this.options.dataType,
            beforeSend: this.toggleLoading.bind(this),
            success: (function(_this) {
              return function(data) {
                _this.fullData = data;
                _this.parseData(_this.fullData);
                if (_this.options.filterable && _this.filter && _this.filter.input) {
                  return _this.filter.input.trigger('input');
                }
              };
            // Remote data
            })(this)
          });
        }
      }
      // Init filterable
      if (this.options.filterable) {
        this.filter = new GitLabDropdownFilter(this.filterInput, {
          elIsInput: $(this.el).is('input'),
          filterInputBlur: this.filterInputBlur,
          filterByText: this.options.filterByText,
          onFilter: this.options.onFilter,
          remote: this.options.filterRemote,
          query: this.options.data,
          keys: searchFields,
          elements: (function(_this) {
            return function() {
              selector = '.dropdown-content li:not(' + NON_SELECTABLE_CLASSES + ')';
              if (_this.dropdown.find('.dropdown-toggle-page').length) {
                selector = ".dropdown-page-one " + selector;
              }
              return $(selector);
            };
          })(this),
          data: (function(_this) {
            return function() {
              return _this.fullData;
            };
          })(this),
          callback: (function(_this) {
            return function(data) {
              _this.parseData(data);
              if (_this.filterInput.val() !== '') {
                selector = SELECTABLE_CLASSES;
                if (_this.dropdown.find('.dropdown-toggle-page').length) {
                  selector = ".dropdown-page-one " + selector;
                }
                if ($(_this.el).is('input')) {
                  currentIndex = -1;
                } else {
                  $(selector, _this.dropdown).first().find('a').addClass('is-focused');
                  currentIndex = 0;
                }
              }
            };
          })(this)
        });
      }
      // Event listeners
      this.dropdown.on("shown.bs.dropdown", this.opened);
      this.dropdown.on("hidden.bs.dropdown", this.hidden);
      $(this.el).on("update.label", this.updateLabel);
      this.dropdown.on("click", ".dropdown-menu, .dropdown-menu-close", this.shouldPropagate);
      this.dropdown.on('keyup', (function(_this) {
        return function(e) {
          // Escape key
          if (e.which === 27) {
            return $('.dropdown-menu-close', _this.dropdown).trigger('click');
          }
        };
      })(this));
      this.dropdown.on('blur', 'a', (function(_this) {
        return function(e) {
          var $dropdownMenu, $relatedTarget;
          if (e.relatedTarget != null) {
            $relatedTarget = $(e.relatedTarget);
            $dropdownMenu = $relatedTarget.closest('.dropdown-menu');
            if ($dropdownMenu.length === 0) {
              return _this.dropdown.removeClass('open');
            }
          }
        };
      })(this));
      if (this.dropdown.find(".dropdown-toggle-page").length) {
        this.dropdown.find(".dropdown-toggle-page, .dropdown-menu-back").on("click", (function(_this) {
          return function(e) {
            e.preventDefault();
            e.stopPropagation();
            return _this.togglePage();
          };
        })(this));
      }
      if (this.options.selectable) {
        selector = ".dropdown-content a";
        if (this.dropdown.find(".dropdown-toggle-page").length) {
          selector = ".dropdown-page-one .dropdown-content a";
        }
        this.dropdown.on("click", selector, function(e) {
          var $el, selected;
          $el = $(this);
          selected = self.rowClicked($el);
          if (self.options.clicked) {
            self.options.clicked(selected, $el, e);
          }

          // Update label right after all modifications in dropdown has been done
          if (self.options.toggleLabel) {
            self.updateLabel(selected, $el, self);
          }

          $el.trigger('blur');
        });
      }
    }

    // Finds an element inside wrapper element
    GitLabDropdown.prototype.getElement = function(selector) {
      return this.dropdown.find(selector);
    };

    GitLabDropdown.prototype.toggleLoading = function() {
      return $('.dropdown-menu', this.dropdown).toggleClass(LOADING_CLASS);
    };

    GitLabDropdown.prototype.togglePage = function() {
      var menu;
      menu = $('.dropdown-menu', this.dropdown);
      if (menu.hasClass(PAGE_TWO_CLASS)) {
        if (this.remote) {
          this.remote.execute();
        }
      }
      menu.toggleClass(PAGE_TWO_CLASS);
      // Focus first visible input on active page
      return this.dropdown.find('[class^="dropdown-page-"]:visible :text:visible:first').focus();
    };

    GitLabDropdown.prototype.parseData = function(data) {
      var full_html, groupData, html, name;
      this.renderedData = data;
      if (this.options.filterable && data.length === 0) {
        // render no matching results
        html = [this.noResults()];
      } else {
        // Handle array groups
        if (gl.utils.isObject(data)) {
          html = [];
          for (name in data) {
            groupData = data[name];
            html.push(this.renderItem({
              header: name
            // Add header for each group
            }, name));
            this.renderData(groupData, name).map(function(item) {
              return html.push(item);
            });
          }
        } else {
          // Render each row
          html = this.renderData(data);
        }
      }
      // Render the full menu
      full_html = this.renderMenu(html);
      return this.appendMenu(full_html);
    };

    GitLabDropdown.prototype.renderData = function(data, group) {
      if (group == null) {
        group = false;
      }
      return data.map((function(_this) {
        return function(obj, index) {
          return _this.renderItem(obj, group, index);
        };
      })(this));
    };

    GitLabDropdown.prototype.shouldPropagate = function(e) {
      var $target;
      if (this.options.multiSelect) {
        $target = $(e.target);
        if ($target && !$target.hasClass('dropdown-menu-close') && !$target.hasClass('dropdown-menu-close-icon') && !$target.data('is-link')) {
          e.stopPropagation();
          return false;
        } else {
          return true;
        }
      }
    };

    GitLabDropdown.prototype.opened = function() {
      var contentHtml;
      this.resetRows();
      this.addArrowKeyEvent();

      if (this.options.setIndeterminateIds) {
        this.options.setIndeterminateIds.call(this);
      }
      if (this.options.setActiveIds) {
        this.options.setActiveIds.call(this);
      }
      // Makes indeterminate items effective
      if (this.fullData && this.dropdown.find('.dropdown-menu-toggle').hasClass('js-filter-bulk-update')) {
        this.parseData(this.fullData);
      }
      contentHtml = $('.dropdown-content', this.dropdown).html();
      if (this.remote && contentHtml === "") {
        this.remote.execute();
      }
      if (this.options.filterable) {
        this.filterInput.focus();
      }

      if (this.options.showMenuAbove) {
        this.positionMenuAbove();
      }

      return this.dropdown.trigger('shown.gl.dropdown');
    };

    GitLabDropdown.prototype.positionMenuAbove = function() {
      var $button = $(this.el);
      var $menu = this.dropdown.find('.dropdown-menu');

      $menu.css('top', ($button.height() + $menu.height()) * -1);
    };

    GitLabDropdown.prototype.hidden = function(e) {
      var $input;
      this.resetRows();
      this.removeArrayKeyEvent();
      $input = this.dropdown.find(".dropdown-input-field");
      if (this.options.filterable) {
        $input.blur().val("");
      }
      // Triggering 'keyup' will re-render the dropdown which is not always required
      // specially if we want to keep the state of the dropdown needed for bulk-assignment
      if (!this.options.persistWhenHide) {
        $input.trigger("input");
      }
      if (this.dropdown.find(".dropdown-toggle-page").length) {
        $('.dropdown-menu', this.dropdown).removeClass(PAGE_TWO_CLASS);
      }
      if (this.options.hidden) {
        this.options.hidden.call(this, e);
      }
      return this.dropdown.trigger('hidden.gl.dropdown');
    };

    // Render the full menu
    GitLabDropdown.prototype.renderMenu = function(html) {
      if (this.options.renderMenu) {
        return this.options.renderMenu(html);
      } else {
        var ul = document.createElement('ul');

        for (var i = 0; i < html.length; i++) {
          var el = html[i];

          if (el instanceof jQuery) {
            el = el.get(0);
          }

          if (typeof el === 'string') {
            ul.innerHTML += el;
          } else {
            ul.appendChild(el);
          }
        }

        return ul;
      }
    };

    // Append the menu into the dropdown
    GitLabDropdown.prototype.appendMenu = function(html) {
      var selector;
      selector = '.dropdown-content';
      if (this.dropdown.find(".dropdown-toggle-page").length) {
        selector = ".dropdown-page-one .dropdown-content";
      }
      return $(selector, this.dropdown).empty().append(html);
    };

    GitLabDropdown.prototype.renderItem = function(data, group, index) {
      var field, fieldName, html, selected, text, url, value;
      if (group == null) {
        group = false;
      }
      if (index == null) {
        // Render the row
        index = false;
      }
      html = document.createElement('li');
      if (data === 'divider' || data === 'separator') {
        html.className = data;
        return html;
      }
      // Header
      if (data.header != null) {
        html.className = 'dropdown-header';
        html.innerHTML = data.header;
        return html;
      }
      if (this.options.renderRow) {
        // Call the render function
        html = this.options.renderRow.call(this.options, data, this);
      } else {
        if (!selected) {
          value = this.options.id ? this.options.id(data) : data.id;
          fieldName = this.options.fieldName;

          field = this.dropdown.parent().find("input[name='" + fieldName + "'][value='" + value + "']");
          if (field.length) {
            selected = true;
          }
        }
        // Set URL
        if (this.options.url != null) {
          url = this.options.url(data);
        } else {
          url = data.url != null ? data.url : '#';
        }
        // Set Text
        if (this.options.text != null) {
          text = this.options.text(data);
        } else {
          text = data.text != null ? data.text : '';
        }
        if (this.highlight) {
          text = this.highlightTextMatches(text, this.filterInput.val());
        }
        // Create the list item & the link
        var link = document.createElement('a');

        link.href = url;
        link.innerHTML = text;

        if (selected) {
          link.className = 'is-active';
        }

        if (group) {
          link.dataset.group = group;
          link.dataset.index = index;
        }

        html.appendChild(link);
      }
      return html;
    };

    GitLabDropdown.prototype.highlightTextMatches = function(text, term) {
      var occurrences;
      occurrences = fuzzaldrinPlus.match(text, term);
      return text.split('').map(function(character, i) {
        if (indexOf.call(occurrences, i) >= 0) {
          return "<b>" + character + "</b>";
        } else {
          return character;
        }
      }).join('');
    };

    GitLabDropdown.prototype.noResults = function() {
      var html;
      return html = "<li class='dropdown-menu-empty-link'> <a href='#' class='is-focused'> No matching results. </a> </li>";
    };

    GitLabDropdown.prototype.rowClicked = function(el) {
      var field, fieldName, groupName, isInput, selectedIndex, selectedObject, value;
      fieldName = this.options.fieldName;
      isInput = $(this.el).is('input');
      if (this.renderedData) {
        groupName = el.data('group');
        if (groupName) {
          selectedIndex = el.data('index');
          selectedObject = this.renderedData[groupName][selectedIndex];
        } else {
          selectedIndex = el.closest('li').index();
          selectedObject = this.renderedData[selectedIndex];
        }
      }

      if (this.options.vue) {
        if (el.hasClass(ACTIVE_CLASS)) {
          el.removeClass(ACTIVE_CLASS);
        } else {
          el.addClass(ACTIVE_CLASS);
        }

        return selectedObject;
      }

      field = [];
      value = this.options.id ? this.options.id(selectedObject, el) : selectedObject.id;
      if (isInput) {
        field = $(this.el);
      } else if(value) {
        field = this.dropdown.parent().find("input[name='" + fieldName + "'][value='" + value.toString().replace(/'/g, '\\\'') + "']");
      }
      if (el.hasClass(ACTIVE_CLASS)) {
        el.removeClass(ACTIVE_CLASS);
        if (field && field.length) {
          if (isInput) {
            field.val('');
          } else {
            field.remove();
          }
        }
      } else if (el.hasClass(INDETERMINATE_CLASS)) {
        el.addClass(ACTIVE_CLASS);
        el.removeClass(INDETERMINATE_CLASS);
        if (field && field.length && value == null) {
          field.remove();
        }
        if ((!field || !field.length) && fieldName) {
          this.addInput(fieldName, value, selectedObject);
        }
      } else {
        if (!this.options.multiSelect || el.hasClass('dropdown-clear-active')) {
          this.dropdown.find("." + ACTIVE_CLASS).removeClass(ACTIVE_CLASS);
          if (!isInput) {
            this.dropdown.parent().find("input[name='" + fieldName + "']").remove();
          }
        }
        if (field && field.length && value == null) {
          field.remove();
        }
        // Toggle active class for the tick mark
        el.addClass(ACTIVE_CLASS);
        if (value != null) {
          if ((!field || !field.length) && fieldName) {
            this.addInput(fieldName, value, selectedObject);
          } else if (field && field.length) {
            field.val(value).trigger('change');
          }
        }
      }

      return selectedObject;
    };

    GitLabDropdown.prototype.addInput = function(fieldName, value, selectedObject) {
      var $input;
      // Create hidden input for form
      $input = $('<input>').attr('type', 'hidden').attr('name', fieldName).val(value);
      if (this.options.inputId != null) {
        $input.attr('id', this.options.inputId);
      }
      return this.dropdown.before($input);
    };

    GitLabDropdown.prototype.selectRowAtIndex = function(index) {
      var $el, selector;
      // If we pass an option index
      if (typeof index !== "undefined") {
        selector = SELECTABLE_CLASSES + ":eq(" + index + ") a";
      } else {
        selector = ".dropdown-content .is-focused";
      }
      if (this.dropdown.find(".dropdown-toggle-page").length) {
        selector = ".dropdown-page-one " + selector;
      }
      // simulate a click on the first link
      $el = $(selector, this.dropdown);
      if ($el.length) {
        var href = $el.attr('href');
        if (href && href !== '#') {
          Turbolinks.visit(href);
        } else {
          $el.first().trigger('click');
        }
      }
    };

    GitLabDropdown.prototype.addArrowKeyEvent = function() {
      var $input, ARROW_KEY_CODES, selector;
      ARROW_KEY_CODES = [38, 40];
      $input = this.dropdown.find(".dropdown-input-field");
      selector = SELECTABLE_CLASSES;
      if (this.dropdown.find(".dropdown-toggle-page").length) {
        selector = ".dropdown-page-one " + selector;
      }
      return $('body').on('keydown', (function(_this) {
        return function(e) {
          var $listItems, PREV_INDEX, currentKeyCode;
          currentKeyCode = e.which;
          if (ARROW_KEY_CODES.indexOf(currentKeyCode) >= 0) {
            e.preventDefault();
            e.stopImmediatePropagation();
            PREV_INDEX = currentIndex;
            $listItems = $(selector, _this.dropdown);
            // if @options.filterable
            //   $input.blur()
            if (currentKeyCode === 40) {
              // Move down
              if (currentIndex < ($listItems.length - 1)) {
                currentIndex += 1;
              }
            } else if (currentKeyCode === 38) {
              // Move up
              if (currentIndex > 0) {
                currentIndex -= 1;
              }
            }
            if (currentIndex !== PREV_INDEX) {
              _this.highlightRowAtIndex($listItems, currentIndex);
            }
            return false;
          }
          if (currentKeyCode === 13 && currentIndex !== -1) {
            e.preventDefault();
            _this.selectRowAtIndex();
          }
        };
      })(this));
    };

    GitLabDropdown.prototype.removeArrayKeyEvent = function() {
      return $('body').off('keydown');
    };

    GitLabDropdown.prototype.resetRows = function resetRows() {
      currentIndex = -1;
      $('.is-focused', this.dropdown).removeClass('is-focused');
    };

    GitLabDropdown.prototype.highlightRowAtIndex = function($listItems, index) {
      var $dropdownContent, $listItem, dropdownContentBottom, dropdownContentHeight, dropdownContentTop, dropdownScrollTop, listItemBottom, listItemHeight, listItemTop;
      // Remove the class for the previously focused row
      $('.is-focused', this.dropdown).removeClass('is-focused');
      // Update the class for the row at the specific index
      $listItem = $listItems.eq(index);
      $listItem.find('a:first-child').addClass("is-focused");
      // Dropdown content scroll area
      $dropdownContent = $listItem.closest('.dropdown-content');
      dropdownScrollTop = $dropdownContent.scrollTop();
      dropdownContentHeight = $dropdownContent.outerHeight();
      dropdownContentTop = $dropdownContent.prop('offsetTop');
      dropdownContentBottom = dropdownContentTop + dropdownContentHeight;
      // Get the offset bottom of the list item
      listItemHeight = $listItem.outerHeight();
      listItemTop = $listItem.prop('offsetTop');
      listItemBottom = listItemTop + listItemHeight;
      if (!index) {
        // Scroll the dropdown content to the top
        $dropdownContent.scrollTop(0)
      } else if (index === ($listItems.length - 1)) {
        // Scroll the dropdown content to the bottom
        $dropdownContent.scrollTop($dropdownContent.prop('scrollHeight'));
      } else if (listItemBottom > (dropdownContentBottom + dropdownScrollTop)) {
        // Scroll the dropdown content down
        $dropdownContent.scrollTop(listItemBottom - dropdownContentBottom + CURSOR_SELECT_SCROLL_PADDING);
      } else if (listItemTop < (dropdownContentTop + dropdownScrollTop)) {
        // Scroll the dropdown content up
        return $dropdownContent.scrollTop(listItemTop - dropdownContentTop - CURSOR_SELECT_SCROLL_PADDING);
      }
    };

    GitLabDropdown.prototype.updateLabel = function(selected, el, instance) {
      if (selected == null) {
        selected = null;
      }
      if (el == null) {
        el = null;
      }
      if (instance == null) {
        instance = null;
      }
      return $(this.el).find(".dropdown-toggle-text").text(this.options.toggleLabel(selected, el, instance));
    };

    return GitLabDropdown;

  })();

  $.fn.glDropdown = function(opts) {
    return this.each(function() {
      if (!$.data(this, 'glDropdown')) {
        return $.data(this, 'glDropdown', new GitLabDropdown(this, opts));
      }
    });
  };

}).call(this);
