/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, one-var, one-var-declaration-per-line, object-shorthand, prefer-arrow-callback, comma-dangle, prefer-template, quotes, no-else-return, max-len */
import Flash from './flash';
import Api from './api';

(function() {
  this.Search = (function() {
    function Search() {
      var $groupDropdown, $projectDropdown;
      $groupDropdown = $('.js-search-group-dropdown');
      $projectDropdown = $('.js-search-project-dropdown');
      this.groupId = $groupDropdown.data('group-id');
      this.eventListeners();
      $groupDropdown.glDropdown({
        selectable: true,
        filterable: true,
        fieldName: 'group_id',
        search: {
          fields: ['full_name']
        },
        data: function(term, callback) {
          return Api.groups(term, {}, function(data) {
            data.unshift({
              full_name: 'Any'
            });
            data.splice(1, 0, 'divider');
            return callback(data);
          });
        },
        id: function(obj) {
          return obj.id;
        },
        text: function(obj) {
          return obj.full_name;
        },
        toggleLabel: function(obj) {
          return ($groupDropdown.data('default-label')) + " " + obj.full_name;
        },
        clicked: (function(_this) {
          return function() {
            return _this.submitSearch();
          };
        })(this)
      });
      $projectDropdown.glDropdown({
        selectable: true,
        filterable: true,
        fieldName: 'project_id',
        search: {
          fields: ['name']
        },
        data: (term, callback) => {
          this.getProjectsData(term)
            .then((data) => {
              data.unshift({
                name_with_namespace: 'Any'
              });
              data.splice(1, 0, 'divider');

              return data;
            })
            .then(data => callback(data))
            .catch(() => new Flash('Error fetching projects'));
        },
        id: function(obj) {
          return obj.id;
        },
        text: function(obj) {
          return obj.name_with_namespace;
        },
        toggleLabel: function(obj) {
          return ($projectDropdown.data('default-label')) + " " + obj.name_with_namespace;
        },
        clicked: (function(_this) {
          return function() {
            return _this.submitSearch();
          };
        })(this)
      });
    }

    Search.prototype.eventListeners = function() {
      $(document).off('keyup', '.js-search-input').on('keyup', '.js-search-input', this.searchKeyUp);
      return $(document).off('click', '.js-search-clear').on('click', '.js-search-clear', this.clearSearchField);
    };

    Search.prototype.submitSearch = function() {
      return $('.js-search-form').submit();
    };

    Search.prototype.searchKeyUp = function() {
      var $input;
      $input = $(this);
      if ($input.val() === '') {
        return $('.js-search-clear').addClass('hidden');
      } else {
        return $('.js-search-clear').removeClass('hidden');
      }
    };

    Search.prototype.clearSearchField = function() {
      return $('.js-search-input').val('').trigger('keyup').focus();
    };

    Search.prototype.getProjectsData = function(term) {
      return new Promise((resolve) => {
        if (this.groupId) {
          Api.groupProjects(this.groupId, term, resolve);
        } else {
          Api.projects(term, {
            order_by: 'id',
          }, resolve);
        }
      });
    };

    return Search;
  })();
}).call(window);
