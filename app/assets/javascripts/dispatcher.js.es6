/* eslint-disable func-names, space-before-function-paren, no-var, prefer-arrow-callback, wrap-iife, no-shadow, consistent-return, one-var, one-var-declaration-per-line, camelcase, default-case, no-new, quotes, no-duplicate-case, no-case-declarations, no-fallthrough, max-len */
/* global UsernameValidator */
/* global ActiveTabMemoizer */
/* global ShortcutsNavigation */
/* global Build */
/* global Issuable */
/* global Issue */
/* global ShortcutsIssuable */
/* global ZenMode */
/* global Milestone */
/* global IssuableForm */
/* global LabelsSelect */
/* global MilestoneSelect */
/* global MergedButtons */
/* global Commit */
/* global NotificationsForm */
/* global TreeView */
/* global NotificationsDropdown */
/* global UsersSelect */
/* global GroupAvatar */
/* global LineHighlighter */
/* global ProjectFork */
/* global BuildArtifacts */
/* global GroupsSelect */
/* global Search */
/* global Admin */
/* global NamespaceSelects */
/* global ShortcutsDashboardNavigation */
/* global Project */
/* global ProjectAvatar */
/* global CompareAutocomplete */
/* global ProjectNew */
/* global Star */
/* global ProjectShow */
/* global Labels */
/* global Shortcuts */
/* global WeightSelect */
/* global AdminEmailSelect */

const ShortcutsBlob = require('./shortcuts_blob');
const UserCallout = require('./user_callout');

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
      var page, path, shortcut_handler;
      page = $('body').attr('data-page');
      if (!page) {
        return false;
      }
      path = page.split(':');
      shortcut_handler = null;
      switch (page) {
        case 'sessions:new':
          new UsernameValidator();
          new ActiveTabMemoizer();
          break;
        case 'projects:boards:show':
        case 'projects:boards:index':
          shortcut_handler = new ShortcutsNavigation();
          break;
        case 'projects:builds:show':
          new Build();
          break;
        case 'projects:merge_requests:index':
        case 'projects:issues:index':
          if (gl.FilteredSearchManager) {
            new gl.FilteredSearchManager(page === 'projects:issues:index' ? 'issues' : 'merge_requests');
          }
          Issuable.init();
          new gl.IssuableBulkActions({
            prefixId: page === 'projects:merge_requests:index' ? 'merge_request_' : 'issue_',
          });
          shortcut_handler = new ShortcutsNavigation();
          break;
        case 'projects:issues:show':
          new Issue();
          shortcut_handler = new ShortcutsIssuable();
          new ZenMode();
          break;
        case 'projects:milestones:show':
        case 'groups:milestones:show':
        case 'dashboard:milestones:show':
          new Milestone();
          break;
        case 'dashboard:todos:index':
          new gl.Todos();
          break;
        case 'projects:milestones:new':
        case 'projects:milestones:edit':
        case 'projects:milestones:update':
          new ZenMode();
          new gl.DueDateSelectors();
          new gl.GLForm($('.milestone-form'));
          break;
        case 'groups:milestones:new':
          new ZenMode();
          break;
        case 'projects:compare:show':
          new gl.Diff();
          break;
        case 'projects:branches:index':
          gl.AjaxLoadingSpinner.init();
          break;
        case 'projects:issues:new':
        case 'projects:issues:edit':
          shortcut_handler = new ShortcutsNavigation();
          new gl.GLForm($('.issue-form'));
          new IssuableForm($('.issue-form'));
          new LabelsSelect();
          new MilestoneSelect();
          new WeightSelect();
          new gl.IssuableTemplateSelectors();
          break;
        case 'projects:merge_requests:new':
        case 'projects:merge_requests:new_diffs':
        case 'projects:merge_requests:edit':
          new gl.Diff();
          shortcut_handler = new ShortcutsNavigation();
          new gl.GLForm($('.merge-request-form'));
          new IssuableForm($('.merge-request-form'));
          new LabelsSelect();
          new MilestoneSelect();
          new gl.IssuableTemplateSelectors();
          break;
        case 'projects:tags:new':
          new ZenMode();
          new gl.GLForm($('.tag-form'));
          break;
        case 'projects:releases:edit':
          new ZenMode();
          new gl.GLForm($('.release-form'));
          break;
        case 'projects:merge_requests:show':
          new gl.Diff();
          shortcut_handler = new ShortcutsIssuable(true);
          new ZenMode();
          new MergedButtons();
          break;
        case 'projects:merge_requests:commits':
          new MergedButtons();
          break;
        case "projects:merge_requests:diffs":
          new gl.Diff();
          new ZenMode();
          new MergedButtons();
          break;
        case 'dashboard:activity':
          new gl.Activities();
          break;
        case 'dashboard:projects:starred':
          new gl.Activities();
          break;
        case 'projects:commit:show':
          new Commit();
          new gl.Diff();
          new ZenMode();
          shortcut_handler = new ShortcutsNavigation();
          break;
        case 'projects:commit:pipelines':
          new gl.MiniPipelineGraph({
            container: '.js-pipeline-table',
          }).bindEvents();
          break;
        case 'projects:commits:show':
        case 'projects:activity':
          shortcut_handler = new ShortcutsNavigation();
          break;
        case 'projects:show':
          shortcut_handler = new ShortcutsNavigation();
          new NotificationsForm();
          if ($('#tree-slider').length) {
            new TreeView();
          }
          break;
        case 'projects:pipelines:builds':
        case 'projects:pipelines:show':
          const { controllerAction } = document.querySelector('.js-pipeline-container').dataset;

          new gl.Pipelines({
            initTabs: true,
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
          break;
        case 'groups:group_members:index':
          new gl.MemberExpirationDate();
          new gl.Members();
          new UsersSelect();
          break;
        case 'projects:members:show':
          new gl.MemberExpirationDate('.js-access-expiration-date-groups');
          new GroupsSelect();
          new gl.MemberExpirationDate();
          new gl.Members();
          new UsersSelect();
          break;
        case 'groups:new':
        case 'groups:edit':
        case 'admin:groups:edit':
        case 'admin:groups:new':
          new GroupAvatar();
          break;
        case 'projects:tree:show':
          shortcut_handler = new ShortcutsNavigation();
          new TreeView();
          break;
        case 'projects:find_file:show':
          shortcut_handler = true;
          break;
        case 'projects:blob:show':
        case 'projects:blame:show':
          new LineHighlighter();
          shortcut_handler = new ShortcutsNavigation();
          const fileBlobPermalinkUrlElement = document.querySelector('.js-data-file-blob-permalink-url');
          const fileBlobPermalinkUrl = fileBlobPermalinkUrlElement && fileBlobPermalinkUrlElement.getAttribute('href');
          new ShortcutsBlob({
            skipResetBindings: true,
            fileBlobPermalinkUrl,
          });
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
          new BuildArtifacts();
          break;
        case 'help:index':
          gl.VersionCheckImage.bindErrorEvent($('img.js-version-status-badge'));
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
        case 'projects:protected_branches:index':
          new gl.ProtectedBranchCreate();
          new gl.ProtectedBranchEditList();
          break;
        case 'projects:ci_cd:show':
          new gl.ProjectVariables();
          break;
        case 'ci:lints:create':
        case 'ci:lints:show':
          new gl.CILintEditor();
          break;
        case 'users:show':
          new UserCallout();
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
            case 'application_settings':
              new gl.ApplicationSettings();
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
          }
          break;
        case 'dashboard':
        case 'root':
          shortcut_handler = new ShortcutsDashboardNavigation();
          new UserCallout();
          break;
        case 'profiles':
          new NotificationsForm();
          new NotificationsDropdown();
          break;
        case 'projects':
          new Project();
          new ProjectAvatar();
          switch (path[1]) {
            case 'compare':
              new CompareAutocomplete();
              break;
            case 'edit':
              shortcut_handler = new ShortcutsNavigation();
              new ProjectNew();
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
              new gl.Wikis();
              shortcut_handler = new ShortcutsNavigation();
              new ZenMode();
              new gl.GLForm($('.wiki-form'));
              break;
            case 'snippets':
              shortcut_handler = new ShortcutsNavigation();
              if (path[2] === 'show') {
                new ZenMode();
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
            case 'protected_branches':
              shortcut_handler = new ShortcutsNavigation();
          }
      }
      // If we haven't installed a custom shortcut handler, install the default one
      if (!shortcut_handler) {
        new Shortcuts();
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
