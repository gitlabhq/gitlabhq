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
        case "projects:merge_requests:conflicts":
          window.mcui = new MergeConflictResolver()
        case 'dashboard:activity':
          new Activities();
          break;
        case 'dashboard:projects:starred':
          new Activities();
          break;
        case 'projects:commit:show':
          new Commit();
          break;
        case 'projects:commits:show':
        case 'projects:activity':
          break;
        case 'projects:show':
          new NotificationsForm();
          if ($('#tree-slider').length) {
            new TreeView();
          }
          break;
        case 'groups:activity':
          new Activities();
          break;
        case 'groups:show':
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
          new TreeView();
          break;
        case 'projects:find_file:show':
          shortcut_handler = true;
          break;
        case 'projects:blob:show':
        case 'projects:blame:show':
          new LineHighlighter();
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
        case 'projects:group_links:index':
          new gl.MemberExpirationDate();
          new GroupsSelect();
          break;
        case 'search:show':
          new Search();
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
              break;
          }
      }
      // If we haven't installed a custom shortcut handler, install the default one
      if (!shortcut_handler) {
        return new Shortcuts();
      }
    };

    Dispatcher.prototype.initSearch = function() {
      // Only when search form is present
      if ($('.search').length) {
        return new SearchAutocomplete();
      }
    };

    return Dispatcher;

  })();

}).call(this);
