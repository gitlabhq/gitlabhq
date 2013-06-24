$ ->
  new Dispatcher()

class Dispatcher
  constructor: () ->
    @initSearch()
    @initPageScripts()

  initPageScripts: ->
    page = $('body').attr('data-page')
    project_id = $('body').attr('data-project-id')

    unless page
      return false

    path = page.split(':')

    switch page
      when 'issues:index'
        Issues.init()
      when 'dashboard:show'
        new Dashboard()
      when 'commit:show'
        new Commit()
      when 'groups:show', 'teams:show', 'projects:show'
        Pager.init(20, true)
      when 'projects:new', 'projects:edit'
        new Project()
      when 'walls:show'
        new Wall(project_id)
      when 'teams:members:index'
        new TeamMembers()

    switch path.first()
      when 'admin' then new Admin()
      when 'wikis' then new Wikis()

  initSearch: ->
    autocomplete_json = $('.search-autocomplete-json').data('autocomplete-opts')
    new SearchAutocomplete(autocomplete_json)
