LineBtn = Vue.extend
  props:
    noteId: Number
    resolved: Boolean
  computed:
    buttonText: ->
      if this.resolved then "Mark as un-resolved" else "Mark as resolved"
  methods:
    updateTooltip: ->
      $(this.$el)
        .tooltip('hide')
        .tooltip('fixTitle')
    resolve: ->
      this.$set('resolved', !this.resolved)
      this.$nextTick this.updateTooltip
  compiled: ->
    $(this.$el).tooltip()

Vue.component 'line-btn', LineBtn
