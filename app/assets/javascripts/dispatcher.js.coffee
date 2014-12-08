$ ->
  new Dispatcher()

class Dispatcher
  constructor: () ->
    @initSearch()
    @initHighlight()
    @initPageScripts()

  initPageScripts: ->
    page = $('body').attr('data-page')
    project_id = $('body').attr('data-project-id')

    unless page
      return false

    path = page.split(':')
    shortcut_handler = null

    switch page
      when 'projects:issues:index'
        Issues.init()
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:issues:show'
        new Issue()
        shortcut_handler = new ShortcutsIssueable()
        new ZenMode()
      when 'projects:milestones:show'
        new Milestone()
      when 'projects:milestones:new'
        new ZenMode()
      when 'projects:issues:new','projects:issues:edit'
        GitLab.GfmAutoComplete.setup()
        shortcut_handler = new ShortcutsNavigation()
        new ZenMode()
      when 'projects:merge_requests:new', 'projects:merge_requests:edit'
        GitLab.GfmAutoComplete.setup()
        new Diff()
        shortcut_handler = new ShortcutsNavigation()
        new ZenMode()
      when 'projects:merge_requests:show'
        new Diff()
        shortcut_handler = new ShortcutsIssueable()
        new ZenMode()
      when "projects:merge_requests:diffs"
        new Diff()
      when 'projects:merge_requests:index'
        shortcut_handler = new ShortcutsNavigation()
      when 'dashboard:show'
        new Dashboard()
        new Activities()
      when 'projects:commit:show'
        new Commit()
        new Diff()
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:commits:show'
        shortcut_handler = new ShortcutsNavigation()
      when 'groups:show', 'projects:show'
        new Activities()
        shortcut_handler = new ShortcutsNavigation()
      when 'groups:members'
        new GroupMembers()
        new UsersSelect()
      when 'groups:new', 'groups:edit', 'admin:groups:edit'
        new GroupAvatar()
      when 'projects:tree:show'
        new TreeView()
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:blob:show'
        new BlobView()
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:labels:new', 'projects:labels:edit'
        new Labels()
      when 'projects:network:show'
        # Ensure we don't create a particular shortcut handler here. This is
        # already created, where the network graph is created.
        shortcut_handler = true
      when 'projects:forks:new'
        new ProjectFork()
      when 'users:show'
        new User()

    switch path.first()
      when 'admin'
        new Admin()
        switch path[1]
          when 'groups'
            new UsersSelect()
          when 'projects'
            new NamespaceSelect()
      when 'dashboard'
        shortcut_handler = new ShortcutsDashboardNavigation()
      when 'profiles'
        new Profile()
      when 'projects'
        new Project()
        switch path[1]
          when 'edit'
            shortcut_handler = new ShortcutsNavigation()
            new ProjectNew()
          when 'new'
            new ProjectNew()
          when 'show'
            new ProjectShow()
          when 'issues', 'merge_requests'
            new ProjectUsersSelect()
          when 'wikis'
            new Wikis()
            shortcut_handler = new ShortcutsNavigation()
            new ZenMode()
          when 'snippets', 'labels', 'graphs'
            shortcut_handler = new ShortcutsNavigation()
          when 'team_members', 'deploy_keys', 'hooks', 'services', 'protected_branches'
            shortcut_handler = new ShortcutsNavigation()
            new UsersSelect()


    # If we haven't installed a custom shortcut handler, install the default one
    if not shortcut_handler
      new Shortcuts()

  initSearch: ->
    opts = $('.search-autocomplete-opts')
    path = opts.data('autocomplete-path')
    project_id = opts.data('autocomplete-project-id')
    project_ref = opts.data('autocomplete-project-ref')

    new SearchAutocomplete(path, project_id, project_ref)

  initHighlight: ->
    $('.highlight pre code').each (i, e) ->
      $(e).html($.map($(e).html().split("\n"), (line, i) ->
        "<span class='line' id='LC" + (i + 1) + "'>" + line + "</span>"
      ).join("\n"))
      hljs.highlightBlock(e)
