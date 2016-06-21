class @WeightSelect
  constructor: ->
    $('.js-weight-select').each (i, dropdown) ->
      $dropdown = $(dropdown)
      updateUrl = $dropdown.data('issueUpdate')
      $selectbox = $dropdown.closest('.selectbox')
      $block = $selectbox.closest('.block')
      $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon span')
      $value = $block.find('.value')
      abilityName = $dropdown.data('ability-name')
      $loading = $block.find('.block-loading').fadeOut()

      updateWeight = (selected) ->
        data = {}
        data[abilityName] = {}
        data[abilityName].weight = if selected? then selected else null
        $loading
          .fadeIn()
        $dropdown.trigger('loading.gl.dropdown')
        $.ajax(
          type: 'PUT'
          dataType: 'json'
          url: updateUrl
          data: data
        ).done (data) ->
          $dropdown.trigger('loaded.gl.dropdown')
          $loading.fadeOut()
          $selectbox.hide()

          if data.weight?
            $value.html(data.weight)
          else
            $value.html('None')
          $sidebarCollapsedValue.html(data.weight)

      $dropdown.glDropdown(
        selectable: true
        fieldName: $dropdown.data("field-name")
        hidden: (e) ->
          $selectbox.hide()
          # display:block overrides the hide-collapse rule
          $value.css('display', '')
        id: (obj, el) ->
          if not $(el).data("none")?
            $(el).data "id"
        clicked: (selected) ->
          if $(dropdown).is ".js-filter-submit"
            $(dropdown).parents('form').submit()
          else
            selected = $dropdown
              .closest('.selectbox')
              .find("input[name='#{$dropdown.data('field-name')}']").val()
            updateWeight(selected)
      )
