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

    switch page
      when 'projects:issues:index'
        Issues.init()
      when 'projects:issues:show'
        new Issue()
      when 'projects:issues:new', 'projects:merge_requests:new'
        GitLab.GfmAutoComplete.setup()
      when 'dashboard:show'
        new Dashboard()
        new Activities()
      when 'projects:commit:show'
        new Commit()
      when 'groups:show', 'projects:show'
        new Activities()
      when 'projects:new', 'projects:edit'
        new Project()
      when 'projects:walls:show'
        new Wall(project_id)
      when 'projects:teams:members:index'
        new TeamMembers()
      when 'groups:members'
        new GroupMembers()
      when 'projects:tree:show'
        new TreeView()
      when 'projects:blob:show'
        new BlobView()

    switch path.first()
      when 'admin' then new Admin()
      when 'projects'
        new Wikis() if path[1] == 'wikis'


  initSearch: ->
    opts = $('.search-autocomplete-opts')
    path = opts.data('autocomplete-path')
    project_id = opts.data('autocomplete-project-id')
    project_ref = opts.data('autocomplete-project-ref')

    new SearchAutocomplete(path, project_id, project_ref)

  initHighlight: ->
    $('.highlight pre code').each (i, e) ->
      hljs.highlightBlock(e)
      $(e).html($.map($(e).html().split("\n"), (line, i) ->
        "<div class='line' id='LC" + (i + 1) + "'>" + line + "</div>"
      ).join("\n"))
