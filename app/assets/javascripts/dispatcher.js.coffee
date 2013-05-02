$ ->
  new Dispatcher()
  
class Dispatcher
  constructor: () ->
    page = $('body').attr('data-page')

    console.log(page)

    switch page
      when 'issues:index' then Issues.init()
      when 'dashboard:show' then dashboardPage()
      when 'groups:show' then Pager.init(20, true)
      when 'teams:show' then Pager.init(20, true)
      when 'projects:show' then Pager.init(20, true)
      when 'projects:new' then new Projects()
      when 'projects:edit' then new Projects()
