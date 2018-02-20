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
          shortcut_handler = true;
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
        case 'projects:services:edit':
          import('./pages/projects/services/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:snippets:edit':
        case 'projects:snippets:update':
          import('./pages/projects/snippets/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:releases:edit':
          import('./pages/projects/releases/edit')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:merge_requests:show':
          shortcut_handler = true;
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
          shortcut_handler = true;
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
          shortcut_handler = true;
          break;
        case 'groups:group_members:index':
          import('./pages/groups/group_members/index')
            .then(callDefault)
            .catch(fail);
          break;
        case 'projects:project_members:index':
          import('./pages/projects/project_members')
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
          break;
        case 'projects:blame:show':
          import('./pages/projects/blame/show')
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
        case 'help:index':
          import('./pages/help')
            .then(callDefault)
            .catch(fail);
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
        case 'dashboard:groups:index':
          import('./pages/dashboard/groups/index')
            .then(callDefault)
            .catch(fail);
          break;
      }
      switch (path[0]) {
        case 'sessions':
          import('./pages/sessions')
            .then(callDefault)
            .catch(fail);
          break;
        case 'omniauth_callbacks':
          import('./pages/omniauth_callbacks')
            .then(callDefault)
            .catch(fail);
          break;
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
