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
      when 'projects:milestones:show'
        new Milestone()
      when 'projects:issues:new'
        GitLab.GfmAutoComplete.setup()
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:merge_requests:new'
        GitLab.GfmAutoComplete.setup()
        new Diff()
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:merge_requests:show'
        new Diff()
        shortcut_handler = new ShortcutsIssueable()
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
      when 'projects:new'
        new Project()
      when 'projects:edit'
        new Project()
        shortcut_handler = new ShortcutsNavigation()
      when 'projects:teams:members:index'
        new TeamMembers()
      when 'groups:members'
        new GroupMembers()
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

    switch path.first()
      when 'admin' then new Admin()
      when 'dashboard'
        shortcut_handler = new ShortcutsDashboardNavigation()
      when 'projects'
        switch path[1]
          when 'wikis'
            new Wikis()
            shortcut_handler = new ShortcutsNavigation()
          when 'snippets', 'labels', 'graphs'
            shortcut_handler = new ShortcutsNavigation()
          when 'team_members', 'deploy_keys', 'hooks', 'services', 'protected_branches'
            shortcut_handler = new ShortcutsNavigation()


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
