/* eslint-disable func-names, space-before-function-paren, no-var, prefer-arrow-callback, wrap-iife, no-shadow, consistent-return, one-var, one-var-declaration-per-line, camelcase, default-case, no-new, quotes, no-duplicate-case, no-case-declarations, no-fallthrough, max-len */
/* global ProjectSelect */
/* global ShortcutsNavigation */
/* global IssuableIndex */
/* global ShortcutsIssuable */
/* global Milestone */
/* global IssuableForm */
/* global LabelsSelect */
/* global MilestoneSelect */
/* global Commit */
/* global NotificationsForm */
/* global NotificationsDropdown */
/* global GroupAvatar */
/* global LineHighlighter */
/* global ProjectFork */
/* global BuildArtifacts */
/* global GroupsSelect */
/* global Search */
/* global Admin */
/* global NamespaceSelects */
/* global Project */
/* global ProjectAvatar */
/* global CompareAutocomplete */
/* global ProjectNew */
/* global ProjectShow */
/* global Labels */
/* global Shortcuts */
/* global Sidebar */
/* global WeightSelect */
/* global AdminEmailSelect */
/* global ShortcutsWiki */

import Issue from './issue';
import BindInOut from './behaviors/bind_in_out';
import DeleteModal from './branches/branches_delete_modal';
import Group from './group';
import GroupName from './group_name';
import GroupsList from './groups_list';
import ProjectsList from './projects_list';
import setupProjectEdit from './project_edit';
import MiniPipelineGraph from './mini_pipeline_graph_dropdown';
import BlobLinePermalinkUpdater from './blob/blob_line_permalink_updater';
import Landing from './landing';
import BlobForkSuggestion from './blob/blob_fork_suggestion';
import UserCallout from './user_callout';
import ShortcutsWiki from './shortcuts_wiki';
import Pipelines from './pipelines';
import BlobViewer from './blob/viewer/index';
import GeoNodes from './geo_nodes';
import AutoWidthDropdownSelect from './issuable/auto_width_dropdown_select';
import UsersSelect from './users_select';
import RefSelectDropdown from './ref_select_dropdown';
import GfmAutoComplete from './gfm_auto_complete';
import ShortcutsBlob from './shortcuts_blob';
import SigninTabsMemoizer from './signin_tabs_memoizer';
import Star from './star';
import Todos from './todos';
import TreeView from './tree';
import UsagePing from './usage_ping';
import UsernameValidator from './username_validator';
import VersionCheckImage from './version_check_image';
import Wikis from './wikis';
import ZenMode from './zen_mode';
import initSettingsPanels from './settings_panels';
import initExperimentalFlags from './experimental_flags';
import OAuthRememberMe from './oauth_remember_me';
import PerformanceBar from './performance_bar';

// EE-only
import ApproversSelect from './approvers_select';
import AuditLogs from './audit_logs';

(function() {
  var Dispatcher;

  $(function() {
    return new Dispatcher();
  });

  Dispatcher = (function() {
    function Dispatcher() {
      this.initSearch();
      this.initFieldErrors();
      this.initPageScripts();
    }

    Dispatcher.prototype.initPageScripts = function() {
      var page, path, shortcut_handler, fileBlobPermalinkUrlElement, fileBlobPermalinkUrl;
      page = $('body').attr('data-page');
      if (!page) {
        return false;
      }
      path = page.split(':');
      shortcut_handler = null;

      $('.js-gfm-input').each((i, el) => {
        const gfm = new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources);
        const enableGFM = gl.utils.convertPermissionToBoolean(el.dataset.supportsAutocomplete);
        gfm.setup($(el), {
          emojis: true,
          members: enableGFM,
          issues: enableGFM,
          milestones: enableGFM,
          mergeRequests: enableGFM,
          labels: enableGFM,
        });
      });

      function initBlob() {
        new LineHighlighter();

        new BlobLinePermalinkUpdater(
          document.querySelector('#blob-content-holder'),
          '.diff-line-num[data-line-number]',
          document.querySelectorAll('.js-data-file-blob-permalink-url, .js-blob-blame-link'),
        );

        shortcut_handler = new ShortcutsNavigation();
        fileBlobPermalinkUrlElement = document.querySelector('.js-data-file-blob-permalink-url');
        fileBlobPermalinkUrl = fileBlobPermalinkUrlElement && fileBlobPermalinkUrlElement.getAttribute('href');
        new ShortcutsBlob({
          skipResetBindings: true,
          fileBlobPermalinkUrl,
        });

        new BlobForkSuggestion({
          openButtons: document.querySelectorAll('.js-edit-blob-link-fork-toggler'),
          forkButtons: document.querySelectorAll('.js-fork-suggestion-button'),
          cancelButtons: document.querySelectorAll('.js-cancel-fork-suggestion-button'),
          suggestionSections: document.querySelectorAll('.js-file-fork-suggestion-section'),
          actionTextPieces: document.querySelectorAll('.js-file-fork-suggestion-section-action'),
        })
          .init();
      }

      switch (page) {
        case 'profiles:preferences:show':
          initExperimentalFlags();
          break;
        case 'sessions:new':
          new UsernameValidator();
          new SigninTabsMemoizer();
          new OAuthRememberMe({ container: $(".omniauth-container") }).bindEvents();
          break;
        case 'projects:boards:show':
        case 'projects:boards:index':
          shortcut_handler = new ShortcutsNavigation();
          new UsersSelect();
          break;
        case 'projects:merge_requests:index':
        case 'projects:issues:index':
          if (gl.FilteredSearchManager && document.querySelector('.filtered-search')) {
            const filteredSearchManager = new gl.FilteredSearchManager(page === 'projects:issues:index' ? 'issues' : 'merge_requests');
            filteredSearchManager.setup();
          }
          const pagePrefix = page === 'projects:merge_requests:index' ? 'merge_request_' : 'issue_';
          IssuableIndex.init(pagePrefix);

          shortcut_handler = new ShortcutsNavigation();
          new UsersSelect();
          break;
        case 'projects:issues:show':
          new Issue();
          shortcut_handler = new ShortcutsIssuable();
          new ZenMode();
          break;
        case 'dashboard:milestones:index':
          new ProjectSelect();
          break;
        case 'projects:milestones:show':
        case 'groups:milestones:show':
        case 'dashboard:milestones:show':
          new Milestone();
          new Sidebar();
          break;
        case 'groups:issues':
        case 'groups:merge_requests':
          new UsersSelect();
          new ProjectSelect();
          break;
        case 'dashboard:todos:index':
          new Todos();
          break;
        case 'dashboard:projects:index':
        case 'dashboard:projects:starred':
        case 'explore:projects:index':
        case 'explore:projects:trending':
        case 'explore:projects:starred':
        case 'admin:projects:index':
          new ProjectsList();
          break;
        case 'explore:groups:index':
          new GroupsList();

          const landingElement = document.querySelector('.js-explore-groups-landing');
          if (!landingElement) break;
          const exploreGroupsLanding = new Landing(
            landingElement,
            landingElement.querySelector('.dismiss-button'),
            'explore_groups_landing_dismissed',
          );
          exploreGroupsLanding.toggle();
          break;
        case 'projects:milestones:new':
        case 'projects:milestones:edit':
        case 'projects:milestones:update':
        case 'groups:milestones:new':
        case 'groups:milestones:edit':
        case 'groups:milestones:update':
          new ZenMode();
          new gl.DueDateSelectors();
          new gl.GLForm($('.milestone-form'), true);
          break;
        case 'projects:compare:show':
          new gl.Diff();
          break;
        case 'projects:branches:index':
          gl.AjaxLoadingSpinner.init();
          new DeleteModal();
          break;
        case 'projects:issues:new':
        case 'projects:issues:edit':
          shortcut_handler = new ShortcutsNavigation();
          new gl.GLForm($('.issue-form'), true);
          new IssuableForm($('.issue-form'));
          new LabelsSelect();
          new MilestoneSelect();
          new WeightSelect();
          new gl.IssuableTemplateSelectors();
          break;
        case 'projects:merge_requests:creations:new':
        case 'projects:merge_requests:creations:diffs':
        case 'projects:merge_requests:edit':
          new gl.Diff();
          shortcut_handler = new ShortcutsNavigation();
          new gl.GLForm($('.merge-request-form'), true);
          new IssuableForm($('.merge-request-form'));
          new LabelsSelect();
          new MilestoneSelect();
          new gl.IssuableTemplateSelectors();
          new AutoWidthDropdownSelect($('.js-target-branch-select')).init();
          break;
        case 'projects:tags:new':
          new ZenMode();
          new gl.GLForm($('.tag-form'), true);
          new RefSelectDropdown($('.js-branch-select'), window.gl.availableRefs);
          break;
        case 'projects:snippets:new':
        case 'projects:snippets:edit':
        case 'projects:snippets:create':
        case 'projects:snippets:update':
          new gl.GLForm($('.snippet-form'), true);
          break;
        case 'snippets:new':
        case 'snippets:edit':
        case 'snippets:create':
        case 'snippets:update':
          new gl.GLForm($('.snippet-form'), false);
          break;
        case 'projects:releases:edit':
          new ZenMode();
          new gl.GLForm($('.release-form'), true);
          break;
        case 'projects:merge_requests:show':
          new gl.Diff();
          shortcut_handler = new ShortcutsIssuable(true);
          new ZenMode();
          break;
        case 'dashboard:activity':
          new gl.Activities();
          break;
        case 'dashboard:issues':
        case 'dashboard:merge_requests':
          new ProjectSelect();
          new UsersSelect();
          break;
        case 'projects:commit:show':
          new Commit();
          new gl.Diff();
          new ZenMode();
          shortcut_handler = new ShortcutsNavigation();
          new MiniPipelineGraph({
            container: '.js-commit-pipeline-graph',
          }).bindEvents();
          break;
        case 'projects:commit:pipelines':
          new MiniPipelineGraph({
            container: '.js-commit-pipeline-graph',
          }).bindEvents();
          break;
        case 'projects:commits:show':
        case 'projects:activity':
          shortcut_handler = new ShortcutsNavigation();
          break;
        case 'projects:edit':
          new UsersSelect();
          break;
        case 'projects:show':
          shortcut_handler = new ShortcutsNavigation();
          new NotificationsForm();
          if ($('#tree-slider').length) {
            new TreeView();
          }
          if ($('.blob-viewer').length) {
            new BlobViewer();
          }
          break;
        case 'projects:edit':
          setupProjectEdit();
          break;
        case 'projects:pipelines:builds':
        case 'projects:pipelines:failures':
        case 'projects:pipelines:show':
          const { controllerAction } = document.querySelector('.js-pipeline-container').dataset;
          const pipelineStatusUrl = `${document.querySelector('.js-pipeline-tab-link a').getAttribute('href')}/status.json`;

          new Pipelines({
            initTabs: true,
            pipelineStatusUrl,
            tabsOptions: {
              action: controllerAction,
              defaultAction: 'pipelines',
              parentEl: '.pipelines-tabs',
            },
          });
          break;
        case 'groups:activity':
          new gl.Activities();
          break;
        case 'groups:show':
          shortcut_handler = new ShortcutsNavigation();
          new NotificationsForm();
          new NotificationsDropdown();
          new ProjectsList();
          break;
        case 'groups:group_members:index':
          new gl.MemberExpirationDate();
          new gl.Members();
          new UsersSelect();
          break;
        case 'projects:project_members:index':
          new gl.MemberExpirationDate('.js-access-expiration-date-groups');
          new GroupsSelect();
          new gl.MemberExpirationDate();
          new gl.Members();
          new UsersSelect();
          break;
        case 'groups:new':
        case 'admin:groups:new':
        case 'groups:create':
        case 'admin:groups:create':
          BindInOut.initAll();
          new Group();
          new GroupAvatar();
          break;
        case 'groups:edit':
        case 'admin:groups:edit':
          new GroupAvatar();
          break;
        case 'projects:tree:show':
          shortcut_handler = new ShortcutsNavigation();
          new TreeView();
          new BlobViewer();
          break;
        case 'projects:find_file:show':
          shortcut_handler = true;
          break;
        case 'projects:blob:show':
          new BlobViewer();
          initBlob();
          break;
        case 'projects:blame:show':
          initBlob();
          break;
        case 'groups:labels:new':
        case 'groups:labels:edit':
        case 'projects:labels:new':
        case 'projects:labels:edit':
          new Labels();
          break;
        case 'projects:labels:index':
          if ($('.prioritized-labels').length) {
            new gl.LabelManager();
          }
          break;
        case 'projects:network:show':
          // Ensure we don't create a particular shortcut handler here. This is
          // already created, where the network graph is created.
          shortcut_handler = true;
          break;
        case 'projects:forks:new':
          new ProjectFork();
          break;
        case 'projects:artifacts:browse':
          new ShortcutsNavigation();
          new BuildArtifacts();
          break;
        case 'projects:artifacts:file':
          new ShortcutsNavigation();
          new BlobViewer();
          break;
        case 'help:index':
          VersionCheckImage.bindErrorEvent($('img.js-version-status-badge'));
          break;
        case 'search:show':
          new Search();
          break;
        case 'projects:mirrors:show':
        case 'projects:mirrors:update':
          new UsersSelect();
          break;
        case 'admin:emails:show':
          new AdminEmailSelect();
          break;
        case 'admin:audit_logs:index':
          new AuditLogs();
          break;
        case 'projects:settings:repository:show':
          new UsersSelect();
          // Initialize expandable settings panels
          initSettingsPanels();
          break;
        case 'projects:settings:ci_cd:show':
        case 'groups:settings:ci_cd:show':
          new gl.ProjectVariables();
          break;
        case 'ci:lints:create':
        case 'ci:lints:show':
          new gl.CILintEditor();
          break;
        case 'users:show':
          new UserCallout();
          break;
        case 'admin:conversational_development_index:show':
          new UserCallout();
          break;
        case 'snippets:show':
          new LineHighlighter();
          new BlobViewer();
          break;
        case 'import:fogbugz:new_user_map':
          new UsersSelect();
          break;
      }
      switch (path.first()) {
        case 'sessions':
        case 'omniauth_callbacks':
          if (!gon.u2f) break;
          gl.u2fAuthenticate = new gl.U2FAuthenticate(
            $('#js-authenticate-u2f'),
            '#js-login-u2f-form',
            gon.u2f,
            document.querySelector('#js-login-2fa-device'),
            document.querySelector('.js-2fa-form'),
          );
          gl.u2fAuthenticate.start();
        case 'admin':
          new Admin();
          switch (path[1]) {
            case 'cohorts':
              new UsagePing();
              break;
            case 'groups':
              new UsersSelect();
              break;
            case 'projects':
              new NamespaceSelects();
              break;
            case 'labels':
              switch (path[2]) {
                case 'new':
                case 'edit':
                  new Labels();
              }
            case 'abuse_reports':
              new gl.AbuseReports();
              break;
            case 'geo_nodes':
              new GeoNodes($('.geo-nodes'));
              break;
          }
          break;
        case 'dashboard':
        case 'root':
          new UserCallout();
          break;
        case 'groups':
          new GroupName();
          break;
        case 'profiles':
          new NotificationsForm();
          new NotificationsDropdown();
          break;
        case 'projects':
          new Project();
          new ProjectAvatar();
          new GroupName();
          switch (path[1]) {
            case 'compare':
              new CompareAutocomplete();
              break;
            case 'edit':
              shortcut_handler = new ShortcutsNavigation();
              new ProjectNew();
              new ApproversSelect();
              break;
            case 'new':
              new ProjectNew();
              break;
            case 'show':
              new Star();
              new ProjectNew();
              new ProjectShow();
              new NotificationsDropdown();
              break;
            case 'wikis':
              new Wikis();
              shortcut_handler = new ShortcutsWiki();
              new ZenMode();
              new gl.GLForm($('.wiki-form'), true);
              break;
            case 'snippets':
              shortcut_handler = new ShortcutsNavigation();
              if (path[2] === 'show') {
                new ZenMode();
                new LineHighlighter();
                new BlobViewer();
              }
              break;
            case 'labels':
            case 'graphs':
            case 'compare':
            case 'pipelines':
            case 'forks':
            case 'milestones':
            case 'project_members':
            case 'deploy_keys':
            case 'builds':
            case 'hooks':
            case 'services':
            case 'repository':
              shortcut_handler = new ShortcutsNavigation();
          }
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
        return new gl.SearchAutocomplete();
      }
    };

    Dispatcher.prototype.initFieldErrors = function() {
      $('.gl-show-field-errors').each((i, form) => {
        new gl.GlFieldErrors(form);
      });
    };

    return Dispatcher;
  })();
}).call(window);
