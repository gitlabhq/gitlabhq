/* eslint-disable func-names, space-before-function-paren, no-var, wrap-iife, one-var, camelcase, one-var-declaration-per-line, quotes, object-shorthand, prefer-arrow-callback, comma-dangle, consistent-return, yoda, prefer-rest-params, prefer-spread, no-unused-vars, prefer-template, max-len */
/* global Api */
(function() {
  var slice = [].slice;

  this.GroupsSelect = (function() {
    function GroupsSelect() {
      $('.ajax-groups-select').each((function(_this) {
        return function(i, select) {
          var all_available, skip_groups;
          all_available = $(select).data('all-available');
          skip_groups = $(select).data('skip-groups') || [];
          return $(select).select2({
            placeholder: "Search for a group",
            multiple: $(select).hasClass('multiselect'),
            minimumInputLength: 0,
            query: function(query) {
              var options = { all_available: all_available, skip_groups: skip_groups };
              return Api.groups(query.term, options, function(groups) {
                var data;
                data = {
                  results: groups
                };
                return query.callback(data);
              });
            },
            initSelection: function(element, callback) {
              var id;
              id = $(element).val();
              if (id !== "") {
                return Api.group(id, callback);
              }
            },
            formatResult: function() {
              var args;
              args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
              return _this.formatResult.apply(_this, args);
            },
            formatSelection: function() {
              var args;
              args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
              return _this.formatSelection.apply(_this, args);
            },
            dropdownCssClass: "ajax-groups-dropdown",
            // we do not want to escape markup since we are displaying html in results
            escapeMarkup: function(m) {
              return m;
            }
          });
        };
      })(this));
      GroupsSelect.visibilityIcon = function (visibilityLevel) {
        switch (visibilityLevel) {
          case 0:
            return 'fa-lock';
          case 10:
            return 'fa-shield';
          case 20:
            return 'fa-globe';
          default:
            return 'fa-globe';
        }
      };
    }

    GroupsSelect.prototype.formatResult = function(group) {
      var avatar, visibility;
      if (group.avatar_url) {
        avatar = group.avatar_url;
      } else {
        avatar = gon.default_group_avatar;
      }

      return `<li class='group-row  ${!group.description ? ' no-description ' : ''}'>
              <div class='stats'><span><i class='fa fa-bookmark'></i>${group.project_count}</span><span><i class='fa fa-users'></i>${group.user_count}</span><span class='visibility-icon has-tooltip' data-container='body' data-placement='left'><i class='fa ${GroupsSelect.visibilityIcon(group.visibility_level)}'></i></span></div>
              <div class='avatar-container s40'><img class='avatar s40 hidden-xs' src='${avatar}'></div>
              <div class='title'>${group.name}</div>
              <div class='description'>
                  <p dir='auto'>${group.description}</p>
              </div>
          </li>`;
    };

    GroupsSelect.prototype.formatSelection = function(group) {
      return group.name;
    };

    return GroupsSelect;
  })();
}).call(this);
