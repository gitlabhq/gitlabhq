$ ->
  new Dispatcher()

class Dispatcher
  constructor: () ->
    @initSearch()
    @initPageScripts()

  initPageScripts: ->
    page = $('body').attr('data-page')

    unless page
      return false

    path = page.split(':')
    shortcut_handler = null
    switch page
      when 'projects:issues:index'
        Issuable.init()
        new IssuableBulkActions()
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:issues:show'
        new Issue()
        shortcut_handler = new ShortcutsIssuable()
        new ZenMode()
      when 'projects:milestones:show', 'groups:milestones:show', 'dashboard:milestones:show'
        new Milestone()
      when 'dashboard:todos:index'
        new Todos()
      when 'projects:milestones:new', 'projects:milestones:edit'
        new ZenMode()
        new DueDateSelect()
        new GLForm($('.milestone-form'))
      when 'groups:milestones:new'
        new ZenMode()
      when 'projects:compare:show'
        new Diff()
      when 'projects:issues:new','projects:issues:edit'
        shortcut_handler = new ShortcutsNavigation()
        new GLForm($('.issue-form'))
        new IssuableForm($('.issue-form'))
      when 'projects:merge_requests:new', 'projects:merge_requests:edit'
        new Diff()
        shortcut_handler = new ShortcutsNavigation()
        new GLForm($('.merge-request-form'))
        new IssuableForm($('.merge-request-form'))
      when 'projects:tags:new'
        new ZenMode()
        new GLForm($('.tag-form'))
      when 'projects:releases:edit'
        new ZenMode()
        new GLForm($('.release-form'))
      when 'projects:merge_requests:show'
        new Diff()
        shortcut_handler = new ShortcutsIssuable(true)
        new ZenMode()
        new MergedButtons()
      when 'projects:merge_requests:commits', 'projects:merge_requests:builds'
        new MergedButtons()
      when "projects:merge_requests:diffs"
        new Diff()
        new ZenMode()
        new MergedButtons()
      when 'projects:merge_requests:index'
        shortcut_handler = new ShortcutsNavigation()
        Issuable.init()
      when 'dashboard:activity'
        new Activities()
      when 'dashboard:projects:starred'
        new Activities()
      when 'projects:commit:show'
        new Commit()
        new Diff()
        new ZenMode()
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:commits:show', 'projects:activity'
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:show'
        shortcut_handler = new ShortcutsNavigation()

        new NotificationsForm()
        new TreeView() if $('#tree-slider').length
      when 'groups:activity'
        new Activities()
      when 'groups:show'
        shortcut_handler = new ShortcutsNavigation()
        new NotificationsForm()
        new NotificationsDropdown()
      when 'groups:group_members:index'
        new GroupMembers()
        new UsersSelect()
      when 'projects:project_members:index'
        new ProjectMembers()
        new UsersSelect()
      when 'groups:new', 'groups:edit', 'admin:groups:edit', 'admin:groups:new'
        new GroupAvatar()
      when 'projects:tree:show'
        shortcut_handler = new ShortcutsNavigation()
        new TreeView()
      when 'projects:find_file:show'
        shortcut_handler = true
      when 'projects:blob:show', 'projects:blame:show'
        new LineHighlighter()
        shortcut_handler = new ShortcutsNavigation()
        new ShortcutsBlob true
      when 'projects:labels:new', 'projects:labels:edit'
        new Labels()
      when 'projects:labels:index'
        new LabelManager() if $('.prioritized-labels').length
      when 'projects:network:show'
        # Ensure we don't create a particular shortcut handler here. This is
        # already created, where the network graph is created.
        shortcut_handler = true
      when 'projects:forks:new'
        new ProjectFork()
      when 'projects:artifacts:browse'
        new BuildArtifacts()
      when 'projects:group_links:index'
        new GroupsSelect()
      when 'search:show'
        new Search()
      when 'projects:mirrors:show', 'projects:mirrors:update'
        new UsersSelect()
      when 'admin:emails:show'
        new AdminEmailSelect()

    switch path.first()
      when 'admin'
        new Admin()
        switch path[1]
          when 'groups'
            new UsersSelect()
          when 'projects'
            new NamespaceSelects()
      when 'dashboard', 'root'
        shortcut_handler = new ShortcutsDashboardNavigation()
      when 'profiles'
        new NotificationsForm()
        new NotificationsDropdown()
      when 'projects'
        new Project()
        new ProjectAvatar()
        switch path[1]
          when 'compare'
            new CompareAutocomplete()
          when 'edit'
            shortcut_handler = new ShortcutsNavigation()
            new ProjectNew()
          when 'new'
            new ProjectNew()
          when 'show'
            new ProjectNew()
            new ProjectShow()
            new NotificationsDropdown()
          when 'wikis'
            new Wikis()
            shortcut_handler = new ShortcutsNavigation()
            new ZenMode()
            new GLForm($('.wiki-form'))
          when 'snippets'
            shortcut_handler = new ShortcutsNavigation()
            new ZenMode() if path[2] == 'show'
          when 'labels', 'graphs', 'compare', 'pipelines', 'forks', \
          'milestones', 'project_members', 'deploy_keys', 'builds', \
          'hooks', 'services', 'protected_branches'
            shortcut_handler = new ShortcutsNavigation()

    # If we haven't installed a custom shortcut handler, install the default one
    if not shortcut_handler
      new Shortcuts()

  initSearch: ->

    # Only when search form is present
    new SearchAutocomplete() if $('.search').length
