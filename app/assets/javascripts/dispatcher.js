/* eslint-disable func-names, space-before-function-paren, no-var, prefer-arrow-callback, wrap-iife, no-shadow, consistent-return, one-var, one-var-declaration-per-line, camelcase, default-case, no-new, quotes, no-duplicate-case, no-case-declarations, no-fallthrough, max-len */
/* global UsernameValidator */
/* global ActiveTabMemoizer */
/* global ShortcutsNavigation */
/* global Build */
/* global Issuable */
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
/* global Project */
/* global ProjectAvatar */
/* global CompareAutocomplete */
/* global ProjectNew */
/* global Star */
/* global ProjectShow */
/* global Labels */
/* global Shortcuts */
/* global Sidebar */

import Issue from './issue';

import BindInOut from './behaviors/bind_in_out';
import Group from './group';
import GroupName from './group_name';
import GroupsList from './groups_list';
import ProjectsList from './projects_list';
import MiniPipelineGraph from './mini_pipeline_graph_dropdown';
import BlobLinePermalinkUpdater from './blob/blob_line_permalink_updater';
import BlobForkSuggestion from './blob/blob_fork_suggestion';
import UserCallout from './user_callout';
import { ProtectedTagCreate, ProtectedTagEditList } from './protected_tags';
import AutoWidthDropdownSelect from './issuable/auto_width_dropdown_select';

const ShortcutsBlob = require('./shortcuts_blob');

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

        new BlobForkSuggestion(
          document.querySelector('.js-edit-blob-link-fork-toggler'),
          document.querySelector('.js-cancel-fork-suggestion'),
          document.querySelector('.js-file-fork-suggestion-section'),
        );
      }

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
          new Sidebar();
          break;
        case 'dashboard:todos:index':
          new gl.Todos();
          break;
        case 'dashboard:projects:index':
        case 'dashboard:projects:starred':
        case 'explore:projects:index':
        case 'explore:projects:trending':
        case 'explore:projects:starred':
        case 'admin:projects:index':
          new ProjectsList();
          break;
        case 'dashboard:groups:index':
        case 'explore:groups:index':
          new GroupsList();
          break;
        case 'projects:milestones:new':
        case 'projects:milestones:edit':
        case 'projects:milestones:update':
        case 'groups:milestones:new':
        case 'groups:milestones:edit':
        case 'groups:milestones:update':
          new ZenMode();
          new gl.DueDateSelectors();
          new gl.GLForm($('.milestone-form'));
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
          new AutoWidthDropdownSelect($('.js-target-branch-select')).init();
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
          const pipelineStatusUrl = `${document.querySelector('.js-pipeline-tab-link a').getAttribute('href')}/status.json`;

          new gl.Pipelines({
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
        case 'projects:members:show':
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
          gl.TargetBranchDropDown.bootstrap();
          break;
        case 'projects:find_file:show':
          shortcut_handler = true;
          break;
        case 'projects:blob:new':
          gl.TargetBranchDropDown.bootstrap();
          break;
        case 'projects:blob:create':
          gl.TargetBranchDropDown.bootstrap();
          break;
        case 'projects:blob:show':
          gl.TargetBranchDropDown.bootstrap();
          initBlob();
          break;
        case 'projects:blob:edit':
          gl.TargetBranchDropDown.bootstrap();
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
          new BuildArtifacts();
          break;
        case 'help:index':
          gl.VersionCheckImage.bindErrorEvent($('img.js-version-status-badge'));
          break;
        case 'search:show':
          new Search();
          break;
        case 'projects:repository:show':
          // Initialize Protected Branch Settings
          new gl.ProtectedBranchCreate();
          new gl.ProtectedBranchEditList();
          // Initialize Protected Tag Settings
          new ProtectedTagCreate();
          new ProtectedTagEditList();
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
            case 'cohorts':
              new gl.UsagePing();
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
