function Projects() { 
  $("#project_name").live("change", function(){
    var slug = slugify($(this).val());
    $("#project_code").val(slug);
    $("#project_path").val(slug);
  });

  $('.new_project, .edit_project').live('ajax:before', function() {
    $('.project_new_holder, .project_edit_holder').hide();
    $('.save-project-loader').show();
  });

  $('form #project_default_branch').chosen();

  disableButtonIfEmtpyField("#project_name", ".project-submit")
}

function initGitCloneSwitcher() {
  var link_sel = ".project_clone_holder button";
  $(link_sel).bind("click", function(e) {
    $(link_sel).removeClass("active");
    $(this).addClass("active");
    $("#project_clone").val($(this).attr("data-clone"));
  })
}
