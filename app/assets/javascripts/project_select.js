/* eslint-disable func-names */

import $ from 'jquery';
import Api from './api';
import { loadCSSFile } from './lib/utils/css_utils';
import { s__ } from './locale';
import ProjectSelectComboButton from './project_select_combo_button';

const projectSelect = () => {
  loadCSSFile(gon.select2_css_path)
    .then(() => {
      $('.ajax-project-select').each(function (i, select) {
        let placeholder;
        const simpleFilter = $(select).data('simpleFilter') || false;
        const isInstantiated = $(select).data('select2');
        this.groupId = $(select).data('groupId');
        this.userId = $(select).data('userId');
        this.includeGroups = $(select).data('includeGroups');
        this.allProjects = $(select).data('allProjects') || false;
        this.orderBy = $(select).data('orderBy') || 'id';
        this.withIssuesEnabled = $(select).data('withIssuesEnabled');
        this.withMergeRequestsEnabled = $(select).data('withMergeRequestsEnabled');
        this.withShared =
          $(select).data('withShared') === undefined ? true : $(select).data('withShared');
        this.includeProjectsInSubgroups = $(select).data('includeProjectsInSubgroups') || false;
        this.allowClear = $(select).data('allowClear') || false;

        placeholder = s__('ProjectSelect|Search for project');
        if (this.includeGroups) {
          placeholder += s__('ProjectSelect| or group');
        }

        $(select).select2({
          placeholder,
          minimumInputLength: 0,
          query: (query) => {
            let projectsCallback;
            const finalCallback = function (projects) {
              const data = {
                results: projects,
              };
              return query.callback(data);
            };
            if (this.includeGroups) {
              projectsCallback = function (projects) {
                const groupsCallback = function (groups) {
                  const data = groups.concat(projects);
                  return finalCallback(data);
                };
                return Api.groups(query.term, {}, groupsCallback);
              };
            } else {
              projectsCallback = finalCallback;
            }
            if (this.groupId) {
              return Api.groupProjects(
                this.groupId,
                query.term,
                {
                  with_issues_enabled: this.withIssuesEnabled,
                  with_merge_requests_enabled: this.withMergeRequestsEnabled,
                  with_shared: this.withShared,
                  include_subgroups: this.includeProjectsInSubgroups,
                  order_by: 'similarity',
                  simple: true,
                },
                projectsCallback,
              );
            } else if (this.userId) {
              return Api.userProjects(
                this.userId,
                query.term,
                {
                  with_issues_enabled: this.withIssuesEnabled,
                  with_merge_requests_enabled: this.withMergeRequestsEnabled,
                  with_shared: this.withShared,
                  include_subgroups: this.includeProjectsInSubgroups,
                },
                projectsCallback,
              );
            }
            return Api.projects(
              query.term,
              {
                order_by: this.orderBy,
                with_issues_enabled: this.withIssuesEnabled,
                with_merge_requests_enabled: this.withMergeRequestsEnabled,
                membership: !this.allProjects,
              },
              projectsCallback,
            );
          },
          id(project) {
            if (simpleFilter) return project.id;
            return JSON.stringify({
              name: project.name,
              url: project.web_url,
            });
          },
          text(project) {
            return project.name_with_namespace || project.name;
          },

          initSelection(el, callback) {
            // eslint-disable-next-line promise/no-nesting
            return Api.project(el.val()).then(({ data }) => callback(data));
          },

          allowClear: this.allowClear,

          dropdownCssClass: 'ajax-project-dropdown',
        });
        if (isInstantiated || simpleFilter) return select;
        return new ProjectSelectComboButton(select);
      });
    })
    .catch(() => {});
};

export default () => {
  if ($('.ajax-project-select').length) {
    import(/* webpackChunkName: 'select2' */ 'select2/select2')
      .then(projectSelect)
      .catch(() => {});
  }
};
