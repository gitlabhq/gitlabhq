$ ->
  new Dispatcher()
  
class Dispatcher
  constructor: () ->
    page = $('body').attr('data-page')

    console.log(page)

    switch page
      when 'issues:index' then Issues.init()
      when 'dashboard:show' then dashboardPage()
      when 'commit:show' then Commit.init()
      when 'groups:show', 'teams:show', 'projects:show'
        Pager.init(20, true)
      when 'projects:new', 'projects:edit'
        new Projects()
      when 'admin:teams:show', 'admin:groups:show', 'admin:logs:show', 'admin:users:new'
        Admin.init()
