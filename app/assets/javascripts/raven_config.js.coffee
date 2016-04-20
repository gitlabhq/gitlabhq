@raven =
  init: ->
    if gon.sentry_dsn?
      Raven.config(gon.sentry_dsn, {
        includePaths: [/gon.relative_url_root/]
        ignoreErrors: [
          # Random plugins/extensions
          'top.GLOBALS',
          # See: http://blog.errorception.com/2012/03/tale-of-unfindable-js-error. html
          'originalCreateNotification',
          'canvas.contentDocument',
          'MyApp_RemoveAllHighlights',
          'http://tt.epicplay.com',
          'Can\'t find variable: ZiteReader',
          'jigsaw is not defined',
          'ComboSearch is not defined',
          'http://loading.retry.widdit.com/',
          'atomicFindClose',
          # ISP "optimizing" proxy - `Cache-Control: no-transform` seems to
          # reduce this. (thanks @acdha)
          # See http://stackoverflow.com/questions/4113268
          'bmi_SafeAddOnload',
          'EBCallBackMessageReceived',
          # See http://toolbar.conduit.com/Developer/HtmlAndGadget/Methods/JSInjection.aspx
          'conduitPage'
        ],
        ignoreUrls: [
          # Chrome extensions
          /extensions\//i,
          /^chrome:\/\//i,
          # Other plugins
          /127\.0\.0\.1:4001\/isrunning/i,  # Cacaoweb
          /webappstoolbarba\.texthelp\.com\//i,
          /metrics\.itunes\.apple\.com\.edgesuite\.net\//i
        ]
      }).install()

    if gon.current_user_id
      Raven.setUserContext({
        id: gon.current_user_id
      })

$ ->
  raven.init()
