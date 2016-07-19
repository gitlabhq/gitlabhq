class @CompareAutocomplete
  constructor: ->
    @initDropdown()

  initDropdown: ->
    $('.js-compare-dropdown').each ->
      $dropdown = $(@)
      selected = $dropdown.data('selected')

      $dropdown.glDropdown(
        data: (term, callback) ->
          $.ajax(
            url: $dropdown.data('refs-url')
            data:
              ref: $dropdown.data('ref')
          ).done (refs) ->
            callback(refs)
        selectable: true
        filterable: true
        filterByText: true
        fieldName: $dropdown.attr('name')
        filterInput: 'input[type="text"]'
        renderRow: (ref) ->
          if ref.header?
            $('<li />')
              .addClass('dropdown-header')
              .text(ref.header)
          else
            link = $('<a />')
              .attr('href', '#')
              .addClass(if ref is selected then 'is-active' else '')
              .text(ref)
              .attr('data-ref', escape(ref))

            $('<li />')
              .append(link)
        id: (obj, $el) ->
          $el.attr('data-ref')
        toggleLabel: (obj, $el) ->
          $el.text().trim()
      )
