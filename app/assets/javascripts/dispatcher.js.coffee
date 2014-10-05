$ ->
  new Dispatcher()

class Dispatcher
  constructor: () ->
    @handlers =
      'projects:issues:index': [Issues.init, ShortcutsNavigation, @shortcatsEnabled]
      'projects:issues:show': [Issue, ShortcutsIssueable, ZenMode]
      'projects:issues:new': [GfmAutoComplete,
                              ShortcutsNavigation, @shortcatsEnabled, ZenMode]
      'projects:issues:edit': [GfmAutoComplete,
                               ShortcutsNavigation, @shortcatsEnabled, ZenMode]
      'projects:milestones:show': [Milestone]
      'projects:milestones:new': [ZenMode]
      'projects:merge_requests:new': [GfmAutoComplete, Diff,
                                      ShortcutsIssueable, @shortcatsEnabled]
      'projects:merge_requests:edit': [GfmAutoComplete, Diff,
                                      ShortcutsIssueable, @shortcatsEnabled]
      'projects:merge_requests:show': [Diff, ShortcutsIssueable,
                                       @shortcatsEnabled, ZenMode]
      'projects:merge_requests:diffs': [Diff]
      'projects:merge_requests:index': [ShortcutsNavigation, @shortcatsEnabled]
      'projects:commit:show': [Commit, Diff, ShortcutsNavigation, @shortcatsEnabled]
      'projects:commits:show': [ShortcutsNavigation, @shortcatsEnabled]
      'projects:tree:show': [TreeView, ShortcutsNavigation, @shortcatsEnabled]
      'projects:blob:show': [BlobView, ShortcutsNavigation, @shortcatsEnabled]
      'projects:labels:new': [Labels]
      'projects:labels:show': [Labels]
      'projects:network:show': [@shortcatsEnabled]
      'projects:teams:members:index': [TeamMembers]
      'projects:new': [Project]
      'projects:edit': [Project]
      'projects:show': [Activities, ShortcutsNavigation, @shortcatsEnabled]
      'dashboard:show': [Dashboard, Activities]
      'groups:members': [GroupMembers]
      'groups:show': [Activities, ShortcutsNavigation, @shortcatsEnabled]

    @shortcutHandler = false
    @initSearch()
    @initHighlight()
    @initPageScripts()

  initPageScripts: ->
    page = $('body').attr('data-page')

    unless page
      return false

    path = page.split(':')

    handlers = @handlers[page] || []
    for handler in handlers
      new handler()

    switch path.first()
      when 'admin' then new Admin()
      when 'dashboard'
        new ShortcutsDashboardNavigation()
        @shortcatsEnabled()
      when 'projects'
        switch path[1]
          when 'wikis'
            new Wikis()
            new ShortcutsNavigation()
            @shortcatsEnabled()
            new ZenMode()
          when 'snippets', 'labels', 'graphs'
            new ShortcutsNavigation()
            @shortcatsEnabled()
          when 'team_members', 'deploy_keys', 'hooks', 'services', 'protected_branches'
            new ShortcutsNavigation()
            @shortcatsEnabled()

    # If we haven't installed a custom shortcut handler, install the default one
    new Shortcuts() if not @shortcutHandler

  initSearch: ->
    opts = $('.search-autocomplete-opts')
    path = opts.data('autocomplete-path')
    project_id = opts.data('autocomplete-project-id')
    project_ref = opts.data('autocomplete-project-ref')

    new SearchAutocomplete(path, project_id, project_ref)

  shortcatsEnabled: => @shortcutHandler = true

  initHighlight: ->
    $('.highlight pre code').each (i, e) ->
      $(e).html($.map($(e).html().split("\n"), (line, i) ->
        "<span class='line' id='LC" + (i + 1) + "'>" + line + "</span>"
      ).join("\n"))
      hljs.highlightBlock(e)
