class @SubscriptionSelect
  constructor: ->
    $('.js-subscription-event').each (i, el) ->
      fieldName = $(el).data("field-name")

      $(el).glDropdown(
        selectable: true
        fieldName: fieldName
        toggleLabel: (selected, el, instance) =>
          label = 'Subscription'
          $item = instance.dropdown.find('.is-active')
          label = $item.text() if $item.length
          label
        clicked: (item, $el, e)->
          e.preventDefault()
        id: (obj, el) ->
          $(el).data("id")
      )
