/* eslint-disable func-names, space-before-function-paren, no-var, prefer-arrow-callback, wrap-iife, no-shadow, consistent-return, one-var, one-var-declaration-per-line, camelcase, default-case, no-new, quotes, no-duplicate-case, no-case-declarations, no-fallthrough, max-len */
import Milestone from './milestone';
import notificationsDropdown from './notifications_dropdown';
import LineHighlighter from './line_highlighter';
import MergeRequest from './merge_request';
import initCompareAutocomplete from './compare_autocomplete';
import Sidebar from './right_sidebar';
import Flash from './flash';
import BlobViewer from './blob/viewer/index';
import GfmAutoComplete from './gfm_auto_complete';
import Star from './star';
import ZenMode from './zen_mode';
import PerformanceBar from './performance_bar';
import initNotes from './init_notes';
import initIssuableSidebar from './init_issuable_sidebar';
import { convertPermissionToBoolean } from './lib/utils/common_utils';
import GlFieldErrors from './gl_field_errors';
import Shortcuts from './shortcuts';
import ShortcutsIssuable from './shortcuts_issuable';
import U2FAuthenticate from './u2f/authenticate';
import Diff from './diff';
import SearchAutocomplete from './search_autocomplete';

// EE-only
import UsersSelect from './users_select';
import UserCallout from './user_callout';
import initGeoInfoModal from 'ee/init_geo_info_modal'; // eslint-disable-line import/first
import initGroupAnalytics from 'ee/init_group_analytics'; // eslint-disable-line import/first
import initPathLocks from 'ee/path_locks'; // eslint-disable-line import/first
import initApprovals from 'ee/approvals'; // eslint-disable-line import/first
import initLDAPGroupsSelect from 'ee/ldap_groups_select'; // eslint-disable-line import/first

(function() {
  var Dispatcher;

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

      function initBlobEE() {
        const dataEl = document.getElementById('js-file-lock');

        if (dataEl) {
          const {
            toggle_path,
            path,
           } = JSON.parse(dataEl.innerHTML);

          initPathLocks(toggle_path, path);
        }
      }

      switch (page) {
        case 'sessions:new':
          import('./pages/sessions/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:boards:show':
        case 'projects:boards:index':
          import('./pages/projects/boards/index')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:merge_requests:index':
          import('./pages/projects/merge_requests/index')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:issues:index':
          import('./pages/projects/issues/index')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:issues:show':
          import('./pages/projects/issues/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'dashboard:milestones:index':
          import('./pages/dashboard/milestones/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:milestones:show':
          new UserCallout();
        case 'groups:milestones:show':
          new Milestone();
          new Sidebar();
          break;
        case 'dashboard:milestones:show':
          import('./pages/dashboard/milestones/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'dashboard:issues':
          import('./pages/dashboard/issues')
            .then(callDefault)
            .catch(fail);
          break;
        case 'dashboard:merge_requests':
          import('./pages/dashboard/merge_requests')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:issues':
          import('./pages/groups/issues')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:merge_requests':
          import('./pages/groups/merge_requests')
            .then(callDefault)
            .catch(fail);
          break;
        case 'dashboard:todos:index':
          import('./pages/dashboard/todos/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:jobs:index':
          import('./pages/admin/jobs/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'dashboard:projects:index':
        case 'dashboard:projects:starred':
          import('./pages/dashboard/projects')
            .then(callDefault)
            .catch(fail);
          break;
        case 'explore:projects:index':
        case 'explore:projects:trending':
        case 'explore:projects:starred':
          import('./pages/explore/projects')
            .then(callDefault)
            .catch(fail);
          break;
        case 'explore:groups:index':
          import('./pages/explore/groups')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:milestones:new':
        case 'projects:milestones:create':
          import('./pages/projects/milestones/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:milestones:edit':
        case 'projects:milestones:update':
          import('./pages/projects/milestones/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:milestones:new':
        case 'groups:milestones:create':
          import('./pages/groups/milestones/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:milestones:edit':
        case 'groups:milestones:update':
          import('./pages/groups/milestones/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:epics:show':
          new ZenMode();
          break;
        case 'projects:compare:show':
          import('./pages/projects/compare/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:branches:new':
          import('./pages/projects/branches/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:branches:create':
          import('./pages/projects/branches/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:branches:index':
          import('./pages/projects/branches/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:issues:new':
          import('./pages/projects/issues/new')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:issues:edit':
          import('./pages/projects/issues/edit')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:merge_requests:creations:new':
          import('./pages/projects/merge_requests/creations/new')
            .then(callDefault)
            .catch(fail);
          new UserCallout();
        case 'projects:merge_requests:creations:diffs':
          import('./pages/projects/merge_requests/creations/diffs')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          // ee-start
          initApprovals();
          // ee-end
          break;
        case 'projects:merge_requests:edit':
          import('./pages/projects/merge_requests/edit')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          // ee-start
          initApprovals();
          // ee-end
          break;
        case 'projects:tags:new':
          import('./pages/projects/tags/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:snippets:show':
          import('./pages/projects/snippets/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:snippets:new':
        case 'projects:snippets:create':
          import('./pages/projects/snippets/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:snippets:edit':
        case 'projects:snippets:update':
          import('./pages/projects/snippets/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'snippets:new':
          import('./pages/snippets/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'snippets:edit':
          import('./pages/snippets/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'snippets:create':
          import('./pages/snippets/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'snippets:update':
          import('./pages/snippets/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:releases:edit':
          import('./pages/projects/releases/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:merge_requests:show':
          new Diff();
          new ZenMode();

          initIssuableSidebar();
          initNotes();

          const mrShowNode = document.querySelector('.merge-request');
          window.mergeRequest = new MergeRequest({
            action: mrShowNode.dataset.mrAction,
          });
          shortcut_handler = new ShortcutsIssuable(true);
          break;
        case 'dashboard:activity':
          import('./pages/dashboard/activity')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:commit:show':
          import('./pages/projects/commit/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:commit:pipelines':
          import('./pages/projects/commit/pipelines')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:activity':
          import('./pages/projects/activity')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:commits:show':
          import('./pages/projects/commits/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:show':
          import('./pages/projects/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          // ee-start
          initGeoInfoModal();
          // ee-end
          break;
        case 'projects:edit':
          import('./pages/projects/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:imports:show':
          import('./pages/projects/imports/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:pipelines:new':
        case 'projects:pipelines:create':
          import('./pages/projects/pipelines/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:pipelines:builds':
        case 'projects:pipelines:failures':
        case 'projects:pipelines:show':
          import('./pages/projects/pipelines/builds')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:activity':
          import('./pages/groups/activity')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:show':
          import('./pages/groups/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'groups:group_members:index':
          import('./pages/groups/group_members/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:project_members:index':
          import('./pages/projects/project_members/')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:create':
        case 'groups:new':
          import('./pages/groups/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'groups:edit':
          import('./pages/groups/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:groups:create':
        case 'admin:groups:new':
          import('./pages/admin/groups/new')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:groups:edit':
          import('./pages/admin/groups/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:tree:show':
          import('./pages/projects/tree/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:find_file:show':
          import('./pages/projects/find_file/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          break;
        case 'projects:blob:show':
          import('./pages/projects/blob/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          initBlobEE();
          break;
        case 'projects:blame:show':
          import('./pages/projects/blame/show')
            .then(callDefault)
            .catch(fail);
          shortcut_handler = true;
          initBlobEE();
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
        case 'help:index':
          import('./pages/help')
            .then(callDefault)
            .catch(fail);
          break;
        case 'search:show':
          import('./pages/search/show')
            .then(callDefault)
            .catch(fail);
          new UserCallout();
          break;
        case 'projects:mirrors:show':
        case 'projects:mirrors:update':
          new UsersSelect();
          break;
        case 'admin:emails:show':
          import(/* webpackChunkName: "ee_admin_emails_show" */ 'ee/pages/admin/emails/show').then(m => m.default()).catch(fail);
          break;
        case 'admin:audit_logs:index':
          import(/* webpackChunkName: "ee_audit_logs" */ 'ee/pages/admin/audit_logs').then(m => m.default()).catch(fail);
          break;
        case 'projects:settings:repository:show':
          import('./pages/projects/settings/repository/show')
            .then(callDefault)
            .catch(fail);
          // ee-start
          new UsersSelect();
          new UserCallout();
          // ee-end
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
        case 'users:show':
          import('./pages/users/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:conversational_development_index:show':
          import('./pages/admin/conversational_development_index/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'snippets:show':
          import('./pages/snippets/show')
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
        case 'profiles:personal_access_tokens:index':
          import('./pages/profiles/personal_access_tokens')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:clusters:show':
        case 'projects:clusters:update':
        case 'projects:clusters:destroy':
          import('./pages/projects/clusters/show')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:clusters:index':
          import('./pages/projects/clusters/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'admin:licenses:new':
          import(/* webpackChunkName: "admin_licenses" */ 'ee/pages/admin/licenses/new').then(m => m.default()).catch(fail);
          break;
        case 'groups:analytics:show':
          initGroupAnalytics();
          break;
        case 'groups:ldap_group_links:index':
          initLDAPGroupsSelect();
          break;
      }
      switch (path[0]) {
        case 'sessions':
        case 'omniauth_callbacks':
          if (!gon.u2f) break;
          const u2fAuthenticate = new U2FAuthenticate(
            $('#js-authenticate-u2f'),
            '#js-login-u2f-form',
            gon.u2f,
            document.querySelector('#js-login-2fa-device'),
            document.querySelector('.js-2fa-form'),
          );
          u2fAuthenticate.start();
          // needed in rspec
          gl.u2fAuthenticate = u2fAuthenticate;
        case 'admin':
          import('./pages/admin')
            .then(callDefault)
            .catch(fail);
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
                case 'edit':
                  import(/* webpackChunkName: "ee_admin_groups_edit" */ 'ee/pages/admin/groups/edit').then(m => m.default()).catch(fail);
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
            case 'geo_nodes':
              import(/* webpackChunkName: 'geo_node_form' */ './geo/geo_node_form')
                .then(geoNodeForm => geoNodeForm.default($('.js-geo-node-form')))
                .catch(() => {});
              break;
          }
          break;
        case 'dashboard':
        case 'root':
          new UserCallout();
          break;
        case 'profiles':
          import('./pages/profiles/index/')
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
              initCompareAutocomplete();
              break;
            case 'create':
            case 'new':
              import('./pages/projects/new')
                .then(callDefault)
                .catch(fail);
              break;
            case 'show':
              new Star();
              notificationsDropdown();
              break;
            case 'wikis':
              import('./pages/projects/wikis')
                .then(callDefault)
                .catch(fail);
              shortcut_handler = true;
              break;
            case 'snippets':
              if (path[2] === 'show') {
                new ZenMode();
                new LineHighlighter();
                new BlobViewer();
              }
              break;
          }
          break;
      }
      // If we haven't installed a custom shortcut handler, install the default one
      if (!shortcut_handler) {
        new Shortcuts();
      }

      if (document.querySelector('#peek')) {
        new PerformanceBar({ container: '#peek' });
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

  $(window).on('load', function() {
    new Dispatcher();
  });
}).call(window);
