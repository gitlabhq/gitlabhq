/* eslint-disable */
(function() {
  this.ProjectSelect = (function() {
    function ProjectSelect() {
      $('.js-projects-dropdown-toggle').each(function(i, dropdown) {
        var $dropdown;
        $dropdown = $(dropdown);
        return $dropdown.glDropdown({
          filterable: true,
          filterRemote: true,
          search: {
            fields: ['name_with_namespace']
          },
          data: function(term, callback) {
            var finalCallback, projectsCallback;
            finalCallback = function(projects) {
              return callback(projects);
            };
            if (this.includeGroups) {
              projectsCallback = function(projects) {
                var groupsCallback;
                groupsCallback = function(groups) {
                  var data;
                  data = groups.concat(projects);
                  return finalCallback(data);
                };
                return Api.groups(term, false, false, groupsCallback);
              };
            } else {
              projectsCallback = finalCallback;
            }
            if (this.groupId) {
              return Api.groupProjects(this.groupId, term, projectsCallback);
            } else {
              return Api.projects(term, this.orderBy, projectsCallback);
            }
          },
          url: function(project) {
            return project.web_url;
          },
          text: function(project) {
            return project.name_with_namespace;
          }
        });
      });
      $('.ajax-project-select').each(function(i, select) {
        var placeholder;
        this.groupId = $(select).data('group-id');
        this.includeGroups = $(select).data('include-groups');
        this.orderBy = $(select).data('order-by') || 'id';
        placeholder = "Search for project";
        if (this.includeGroups) {
          placeholder += " or group";
        }
        return $(select).select2({
          placeholder: placeholder,
          minimumInputLength: 0,
          query: (function(_this) {
            return function(query) {
              var finalCallback, projectsCallback;
              finalCallback = function(projects) {
                var data;
                data = {
                  results: projects
                };
                return query.callback(data);
              };
              if (_this.includeGroups) {
                projectsCallback = function(projects) {
                  var groupsCallback;
                  groupsCallback = function(groups) {
                    var data;
                    data = groups.concat(projects);
                    return finalCallback(data);
                  };
                  return Api.groups(query.term, false, false, groupsCallback);
                };
              } else {
                projectsCallback = finalCallback;
              }
              if (_this.groupId) {
                return Api.groupProjects(_this.groupId, query.term, projectsCallback);
              } else {
                return Api.projects(query.term, _this.orderBy, projectsCallback);
              }
            };
          })(this),
          id: function(project) {
            return project.web_url;
          },
          text: function(project) {
            return project.name_with_namespace || project.name;
          },
          dropdownCssClass: "ajax-project-dropdown"
        });
      });
    }

    return ProjectSelect;

  })();

}).call(this);
