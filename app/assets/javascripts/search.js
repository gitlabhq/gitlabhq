/* eslint-disable */
(function() {
  this.Search = (function() {
    function Search() {
      var $groupDropdown, $projectDropdown;
      $groupDropdown = $('.js-search-group-dropdown');
      $projectDropdown = $('.js-search-project-dropdown');
      this.eventListeners();
      $groupDropdown.glDropdown({
        selectable: true,
        filterable: true,
        fieldName: 'group_id',
        data: function(term, callback) {
          return Api.groups(term, false, false, function(data) {
            data.unshift({
              name: 'Any'
            });
            data.splice(1, 0, 'divider');
            return callback(data);
          });
        },
        id: function(obj) {
          return obj.id;
        },
        text: function(obj) {
          return obj.name;
        },
        toggleLabel: function(obj) {
          return ($groupDropdown.data('default-label')) + " " + obj.name;
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
        data: function(term, callback) {
          return Api.projects(term, 'id', function(data) {
            data.unshift({
              name_with_namespace: 'Any'
            });
            data.splice(1, 0, 'divider');
            return callback(data);
          });
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

    return Search;

  })();

}).call(this);
