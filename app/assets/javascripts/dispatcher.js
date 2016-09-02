(function() {
  var Dispatcher;

  $(function() {
    return new Dispatcher();
  });

  Dispatcher = (function() {
    function Dispatcher() {
      this.initSearch();
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
        case 'projects:boards:show':
          shortcut_handler = new ShortcutsNavigation();
          break;
        case 'projects:issues:index':
          Issuable.init();
          new IssuableBulkActions();
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
          new Todos();
          break;
        case 'projects:milestones:new':
        case 'projects:milestones:edit':
          new ZenMode();
          new DueDateSelect();
          new GLForm($('.milestone-form'));
          break;
        case 'groups:milestones:new':
          new ZenMode();
          break;
        case 'projects:compare:show':
          new Diff();
          break;
        case 'projects:issues:new':
        case 'projects:issues:edit':
          shortcut_handler = new ShortcutsNavigation();
          new GLForm($('.issue-form'));
          new IssuableForm($('.issue-form'));
          new IssuableTemplateSelectors();
          break;
        case 'projects:merge_requests:new':
        case 'projects:merge_requests:edit':
          new Diff();
          shortcut_handler = new ShortcutsNavigation();
          new GLForm($('.merge-request-form'));
          new IssuableForm($('.merge-request-form'));
          new IssuableTemplateSelectors();
          break;
        case 'projects:tags:new':
          new ZenMode();
          new GLForm($('.tag-form'));
          break;
        case 'projects:releases:edit':
          new ZenMode();
          new GLForm($('.release-form'));
          break;
        case 'projects:merge_requests:show':
          new Diff();
          shortcut_handler = new ShortcutsIssuable(true);
          new ZenMode();
          new MergedButtons();
          break;
        case 'projects:merge_requests:commits':
        case 'projects:merge_requests:builds':
          new MergedButtons();
          break;
        case "projects:merge_requests:diffs":
          new Diff();
          new ZenMode();
          new MergedButtons();
          break;
        case "projects:merge_requests:conflicts":
          window.mcui = new MergeConflictResolver()
        case 'projects:merge_requests:index':
          shortcut_handler = new ShortcutsNavigation();
          Issuable.init();
          break;
        case 'dashboard:activity':
          new Activities();
          break;
        case 'dashboard:projects:starred':
          new Activities();
          break;
        case 'projects:commit:show':
          new Commit();
          new Diff();
          new ZenMode();
          shortcut_handler = new ShortcutsNavigation();
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
        case 'groups:activity':
          new Activities();
          break;
        case 'groups:show':
          shortcut_handler = new ShortcutsNavigation();
          new NotificationsForm();
          new NotificationsDropdown();
          break;
        case 'groups:group_members:index':
          new gl.MemberExpirationDate();
          new GroupMembers();
          new UsersSelect();
          break;
        case 'projects:project_members:index':
          new gl.MemberExpirationDate();
          new ProjectMembers();
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
          new ShortcutsBlob(true);
          break;
        case 'projects:labels:new':
        case 'projects:labels:edit':
          new Labels();
          break;
        case 'projects:labels:index':
          if ($('.prioritized-labels').length) {
            new LabelManager();
          }
          break;
        case 'projects:network:show':
          shortcut_handler = true;
          break;
        case 'projects:forks:new':
          new ProjectFork();
          break;
        case 'projects:artifacts:browse':
          new BuildArtifacts();
          break;
        case 'projects:group_links:index':
          new gl.MemberExpirationDate();
          new GroupsSelect();
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
      }
      switch (path.first()) {
        case 'admin':
          new Admin();
          switch (path[1]) {
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
              new Wikis();
              shortcut_handler = new ShortcutsNavigation();
              new ZenMode();
              new GLForm($('.wiki-form'));
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
      if (!shortcut_handler) {
        return new Shortcuts();
      }
    };

    Dispatcher.prototype.initSearch = function() {
      if ($('.search').length) {
        return new SearchAutocomplete();
      }
    };

    return Dispatcher;

  })();

}).call(this);
