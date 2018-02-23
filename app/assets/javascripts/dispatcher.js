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

      const shortcutHandlerPages = [
        'projects:activity',
        'projects:artifacts:browse',
        'projects:artifacts:file',
        'projects:blame:show',
        'projects:blob:show',
        'projects:commit:show',
        'projects:commits:show',
        'projects:find_file:show',
        'projects:issues:edit',
        'projects:issues:index',
        'projects:issues:new',
        'projects:issues:show',
        'projects:merge_requests:creations:diffs',
        'projects:merge_requests:creations:new',
        'projects:merge_requests:edit',
        'projects:merge_requests:index',
        'projects:merge_requests:show',
        'projects:network:show',
        'projects:show',
        'projects:tree:show',
        'groups:show',
      ];

      if (shortcutHandlerPages.indexOf(page) !== -1) {
        shortcut_handler = true;
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
