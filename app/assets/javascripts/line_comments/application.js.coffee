#= require vue
#= require vue-resource
#= require_directory ./stores
#= require_directory ./services
#= require_directory ./components

$ =>
  @DiffNotesApp = new Vue
    el: '#diff-comments-app'
    components:
      'resolve-btn': ResolveBtn
      'resolve-all': ResolveAll

  new Vue
    el: '#resolve-count-app'
    components:
      'resolve-count': ResolveCount
