#= require vue
#= require_directory ./stores
#= require_directory ./services
#= require_directory ./components

$ =>
  @DiffNotesApp = new Vue
    el: '#notes'
    components:
      'resolve-btn': ResolveBtn

  new Vue
    el: '#resolve-all-app'
    components:
      'resolve-all': ResolveAll
