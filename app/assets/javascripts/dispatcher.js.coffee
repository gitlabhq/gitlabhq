$ ->
  new Dispatcher()
  
class Dispatcher
  constructor: () ->
    page = $('body').attr('data-page')
    project_id = $('body').attr('data-project-id')

    console.log(page)
 
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

    switch path.first()
      when 'admin' then Admin.init()
      when 'wikis' then new Wikis()

