#= require vue
#= require_directory ./stores
#= require_directory ./components

$ ->
  new Vue
    el: '#notes'

  new Vue
    el: '#resolve-all-app'
