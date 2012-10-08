# Code browser tree slider

$ ->
  if $('#tree-slider').length > 0
    # Show the "Loading commit data" for only the first element
    $('span.log_loading:first').removeClass('hide')

    $('#tree-slider .tree-item-file-name a, .breadcrumb li > a').live "click", ->
      $("#tree-content-holder").hide("slide", { direction: "left" }, 150)

    $('.project-refs-form').live
      "ajax:beforeSend": -> $("#tree-content-holder").hide("slide", { direction: "left" }, 150)

    # Make the entire tree-item row clickable, but not if clicking another link (like a commit message)
    $("#tree-slider .tree-item").live 'click', (e) ->
      $('.tree-item-file-name a', this).trigger('click') if (e.target.nodeName != "A")

    # Show/Hide the loading spinner
    $('#tree-slider .tree-item-file-name a, .breadcrumb a, .project-refs-form').live
      "ajax:beforeSend": -> $('.tree_progress').addClass("loading")
      "ajax:complete":   -> $('.tree_progress').removeClass("loading")
