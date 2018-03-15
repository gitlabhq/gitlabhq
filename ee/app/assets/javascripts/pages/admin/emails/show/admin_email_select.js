/* eslint-disable no-var, wrap-iife, func-names, space-before-function-paren, camelcase, no-unused-vars, quotes, object-shorthand, one-var, one-var-declaration-per-line, prefer-arrow-callback, comma-dangle, prefer-template, no-else-return, yoda, prefer-rest-params, prefer-spread, max-len */

import $ from 'jquery';
import Api from '~/api';

var slice = [].slice;

function AdminEmailSelect() {
  $('.ajax-admin-email-select').each((function(_this) {
    return function(i, select) {
      var skip_ldap;
      skip_ldap = $(select).hasClass('skip_ldap');
      return $(select).select2({
        placeholder: "Select group or project",
        multiple: $(select).hasClass('multiselect'),
        minimumInputLength: 0,
        query: function(query) {
          const groupsFetch = Api.groups(query.term, {});
          const projectsFetch = Api.projects(query.term, {
            order_by: 'id',
            membership: false
          });
          return Promise.all([projectsFetch, groupsFetch]).then(function([projects, groups]) {
            var all, data;
            all = {
              id: "all"
            };
            data = [all].concat(groups, projects);
            return query.callback({
              results: data
            });
          });
        },
        id: function(object) {
          if (object.path_with_namespace) {
            return "project-" + object.id;
          } else if (object.path) {
            return "group-" + object.id;
          } else {
            return "all";
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
        dropdownCssClass: "ajax-admin-email-dropdown",
        escapeMarkup: function(m) {
          return m;
        }
      });
    };
  })(this));
}

AdminEmailSelect.prototype.formatResult = function(object) {
  if (object.path_with_namespace) {
    return "<div class='project-result'> <div class='project-name'>" + object.name + "</div> <div class='project-path'>" + object.path_with_namespace + "</div> </div>";
  } else if (object.path) {
    return "<div class='group-result'> <div class='group-name'>" + object.name + "</div> <div class='group-path'>" + object.path + "</div> </div>";
  } else {
    return "<div class='group-result'> <div class='group-name'>All</div> <div class='group-path'>All groups and projects</div> </div>";
  }
};

AdminEmailSelect.prototype.formatSelection = function(object) {
  if (object.path_with_namespace) {
    return "Project: " + object.name;
  } else if (object.path) {
    return "Group: " + object.name;
  } else {
    return "All groups and projects";
  }
};

export default AdminEmailSelect;
