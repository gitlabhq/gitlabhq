window.Projects = ->
  $("#project_name").live "change", ->
    slug = slugify($(this).val())
    $("#project_code").val(slug)
    $("#project_path").val(slug)

  $(".new_project, .edit_project").live "ajax:before", ->
    $(".project_new_holder, .project_edit_holder").hide()
    $(".save-project-loader").show()

  $("form #project_default_branch").chosen()
  disableButtonIfEmtpyField "#project_name", ".project-submit"

# Git clone panel switcher
$ ->
  scope = $('.project_clone_holder')
  if scope.length > 0
    $('a, button', scope).click ->
      $('a, button', scope).removeClass('active')
      $(this).addClass('active')
      $('#project_clone', scope).val($(this).data('clone'))
