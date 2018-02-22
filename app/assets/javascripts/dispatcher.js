/* eslint-disable func-names, space-before-function-paren, no-var, prefer-arrow-callback, wrap-iife, no-shadow, consistent-return, one-var, one-var-declaration-per-line, camelcase, default-case, no-new, quotes, no-duplicate-case, no-case-declarations, no-fallthrough, max-len */
import Flash from './flash';
import GfmAutoComplete from './gfm_auto_complete';
import { convertPermissionToBoolean } from './lib/utils/common_utils';
import GlFieldErrors from './gl_field_errors';
import Shortcuts from './shortcuts';
import SearchAutocomplete from './search_autocomplete';

var Dispatcher;

(function() {
  Dispatcher = (function() {
    function Dispatcher() {
      this.initSearch();
      this.initFieldErrors();
      this.initPageScripts();
    }

    Dispatcher.prototype.initPageScripts = function() {
      var path, shortcut_handler;
      const page = $('body').attr('data-page');
      if (!page) {
        return false;
      }

      const fail = () => Flash('Error loading dynamic module');
      const callDefault = m => m.default();

      path = page.split(':');
      shortcut_handler = null;

      $('.js-gfm-input:not(.js-vue-textarea)').each((i, el) => {
        const gfm = new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources);
        const enableGFM = convertPermissionToBoolean(el.dataset.supportsAutocomplete);
        gfm.setup($(el), {
          emojis: true,
          members: enableGFM,
          issues: enableGFM,
          milestones: enableGFM,
          mergeRequests: enableGFM,
          labels: enableGFM,
        });
      });

      switch (page) {
        case 'projects:merge_requests:index':
        case 'projects:issues:index':
        case 'projects:issues:show':
        case 'projects:issues:new':
        case 'projects:issues:edit':
        case 'projects:merge_requests:creations:new':
        case 'projects:merge_requests:creations:diffs':
        case 'projects:merge_requests:edit':
        case 'projects:merge_requests:show':
        case 'projects:commit:show':
        case 'projects:activity':
        case 'projects:commits:show':
        case 'projects:show':
        case 'groups:show':
        case 'projects:find_file:show':
        case 'projects:blob:show':
        case 'projects:blame:show':
          shortcut_handler = true;
          break;
        case 'projects:tree:show':
          import(/* webpackChunkName: "ee_projects_edit" */ 'ee/pages/projects/tree/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'groups:labels:new':
          import('./pages/groups/labels/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:labels:edit':
          import('./pages/groups/labels/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:labels:new':
          import('./pages/projects/labels/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:labels:edit':
          import('./pages/projects/labels/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:labels:index':
          import('./pages/groups/labels/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:labels:index':
          import('./pages/projects/labels/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:network:show':
          // Ensure we don't create a particular shortcut handler here. This is
          // already created, where the network graph is created.
          shortcut_handler = true;
          break;
        case 'projects:forks:new':
          import('./pages/projects/forks/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:artifacts:browse':
          import('./pages/projects/artifacts/browse')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:artifacts:file':
          import('./pages/projects/artifacts/file')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'search:show':
          import('./pages/search/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:settings:repository:show':
          import('./pages/projects/settings/repository/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:settings:ci_cd:show':
          import('./pages/projects/settings/ci_cd/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:settings:ci_cd:show':
          import('./pages/groups/settings/ci_cd/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'ci:lints:create':
        case 'ci:lints:show':
          import('./pages/ci/lints')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:conversational_development_index:show':
          import('./pages/admin/conversational_development_index/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'import:fogbugz:new_user_map':
          import('./pages/import/fogbugz/new_user_map')
            .then(callDefault)
            .catch(fail);
          break;
        case 'profiles:personal_access_tokens:index':
          import('./pages/profiles/personal_access_tokens')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:impersonation_tokens:index':
          import('./pages/admin/impersonation_tokens')
            .then(callDefault)
            .catch(fail);
          break;
        case 'dashboard:groups:index':
          import('./pages/dashboard/groups/index')
            .then(callDefault)
            .catch(fail);
          break;
      }
      switch (path[0]) {
        case 'admin':
          switch (path[1]) {
            case 'broadcast_messages':
              import('./pages/admin/broadcast_messages')
                .then(callDefault)
                .catch(fail);
              break;
            case 'cohorts':
              import('./pages/admin/cohorts')
                .then(callDefault)
                .catch(fail);
              break;
            case 'groups':
              switch (path[2]) {
                case 'show':
                  import('./pages/admin/groups/show')
                    .then(callDefault)
                    .catch(fail);
                  break;
              }
              break;
            case 'projects':
              import('./pages/admin/projects')
                .then(callDefault)
                .catch(fail);
              break;
            case 'labels':
              switch (path[2]) {
                case 'new':
                  import('./pages/admin/labels/new')
                    .then(callDefault)
                    .catch(fail);
                  break;
                case 'edit':
                  import('./pages/admin/labels/edit')
                    .then(callDefault)
                    .catch(fail);
                  break;
              }
            case 'abuse_reports':
              import('./pages/admin/abuse_reports')
                .then(callDefault)
                .catch(fail);
              break;
          }
          break;
        case 'profiles':
          import('./pages/profiles/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects':
          import('./pages/projects')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          switch (path[1]) {
            case 'compare':
              import('./pages/projects/compare')
                .then(callDefault)
                .catch(fail);
              break;
            case 'create':
            case 'new':
              import('./pages/projects/new')
                .then(callDefault)
                .catch(fail);
              break;
            case 'wikis':
              import('./pages/projects/wikis')
                .then(callDefault)
                .catch(fail);
              shortcut_handler = true;
              break;
          }
          break;
      }
      // If we haven't installed a custom shortcut handler, install the default one
      if (!shortcut_handler) {
        new Shortcuts();
      }

      // EE-only route-based code

      switch (page) {
        case 'groups:epics:show':
          import(/* webpackChunkName: "ee_epics_show" */ 'ee/pages/groups/epics/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:epics:index':
          import(/* webpackChunkName: "ee_epics_index" */ 'ee/pages/groups/epics/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:milestones:show':
          import(/* webpackChunkName: "ee_projects_milestones_show" */ 'ee/pages/projects/milestones/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'search:show':
          import(/* webpackChunkName: "ee_search_show" */ 'ee/pages/search/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:merge_requests:creations:new':
          import(/* webpackChunkName: "ee_merge_requests_creations_new" */ 'ee/pages/projects/merge_requests/creations/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:merge_requests:creations:diffs':
          import(/* webpackChunkName: "ee_merge_requests_creations_diffs" */ 'ee/pages/projects/merge_requests/creations/diffs')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:merge_requests:edit':
          import(/* webpackChunkName: "ee_merge_requests_edit" */ 'ee/pages/projects/merge_requests/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:show':
          import(/* webpackChunkName: "ee_projects_show" */ 'ee/pages/projects/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:blob:show':
          import(/* webpackChunkName: "ee_projects_blob_show" */ 'ee/pages/projects/blob/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:blame:show':
          import(/* webpackChunkName: "ee_projects_blame_show" */ 'ee/pages/projects/blame/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:emails:show':
          import(/* webpackChunkName: "ee_admin_emails_show" */ 'ee/pages/admin/emails/show').then(m => m.default()).catch(fail);
          break;
        case 'admin:audit_logs:index':
          import(/* webpackChunkName: "ee_audit_logs" */ 'ee/pages/admin/audit_logs').then(m => m.default()).catch(fail);
          break;
        case 'projects:settings:repository:show':
          import(/* webpackChunkName: "ee_projects_settings_repository_show" */ 'ee/pages/projects/settings/repository/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:licenses:new':
          import(/* webpackChunkName: "admin_licenses" */ 'ee/pages/admin/licenses/new').then(m => m.default()).catch(fail);
          break;
        case 'groups:analytics:show':
          import(/* webpackChunkName: "ee_groups_analytics_show" */ 'ee/pages/groups/analytics/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:ldap_group_links:index':
          import(/* webpackChunkName: "ee_groups_ldap_links" */ 'ee/pages/groups/ldap_group_links')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:groups:edit':
          import(/* webpackChunkName: "ee_admin_groups_edit" */ 'ee/pages/admin/groups/edit').then(m => m.default()).catch(fail);
          break;
        case 'admin:geo_nodes:new':
          import(/* webpackChunkName: 'ee_admin_geo_nodes_new' */ 'ee/pages/admin/geo_nodes/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:geo_nodes:create':
          import(/* webpackChunkName: 'ee_admin_geo_nodes_create' */ 'ee/pages/admin/geo_nodes/create')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:geo_nodes:edit':
          import(/* webpackChunkName: 'ee_admin_geo_nodes_edit' */ 'ee/pages/admin/geo_nodes/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:geo_nodes:update':
          import(/* webpackChunkName: 'ee_admin_geo_nodes_update' */ 'ee/pages/admin/geo_nodes/update')
            .then(callDefault)
            .catch(fail);
          break;
      }

      if (document.querySelector('#peek')) {
        import('./performance_bar')
          .then(m => new m.default({ container: '#peek' })) // eslint-disable-line new-cap
          .catch(fail);
      }
    };

    Dispatcher.prototype.initSearch = function() {
      // Only when search form is present
      if ($('.search').length) {
        return new SearchAutocomplete();
      }
    };

    Dispatcher.prototype.initFieldErrors = function() {
      $('.gl-show-field-errors').each((i, form) => {
        new GlFieldErrors(form);
      });
    };

    return Dispatcher;
  })();
})();

export default function initDispatcher() {
  return new Dispatcher();
}
