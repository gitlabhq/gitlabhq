class @Project
  constructor: ->
    # Git protocol switcher
    $('ul.clone-options-dropdown a').click ->
      return if $(@).hasClass('active')


      # Remove the active class for all buttons (ssh, http, kerberos if shown)
      $('.active').not($(@)).removeClass('active');
      # Add the active class for the clicked button
      $(@).toggleClass('active')

      url = $("#project_clone").val()

      # Update the input field
      $('#project_clone').val(url)

      # Update the command line instructions
      $('.clone').text(url)

    # Ref switcher
    @initRefSwitcher()
    $('.project-refs-select').on 'change', ->
      $(@).parents('form').submit()

    $('.hide-no-ssh-message').on 'click', (e) ->
      path = '/'
      $.cookie('hide_no_ssh_message', 'false', { path: path })
      $(@).parents('.no-ssh-key-message').remove()
      e.preventDefault()

    $('.hide-no-password-message').on 'click', (e) ->
      path = '/'
      $.cookie('hide_no_password_message', 'false', { path: path })
      $(@).parents('.no-password-message').remove()
      e.preventDefault()

    @projectSelectDropdown()

  projectSelectDropdown: ->
    new ProjectSelect()

    $('.project-item-select').on 'click', (e) =>
      @changeProject $(e.currentTarget).val()

    $('.js-projects-dropdown-toggle').on 'click', (e) ->
      e.preventDefault()

      $('.js-projects-dropdown').select2('open')

  changeProject: (url) ->
    window.location = url

  initRefSwitcher: ->
    $('.js-project-refs-dropdown').each ->
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
        fieldName: 'ref'
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
        clicked: (e) ->
          $dropdown.closest('form').submit()
      )
