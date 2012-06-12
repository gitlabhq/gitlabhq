function switchToNewIssue(form){
  $(".issues_content").hide("fade", { direction: "left" }, 150, function(){
    $(".issues_content").after(form);
    $('select#issue_assignee_id').chosen();
    $('select#issue_milestone_id').chosen();
    $("#new_issue_dialog").show("fade", { direction: "right" }, 150);
    $('.top-tabs .add_new').hide();
  });
}

function switchToEditIssue(form){
  $(".issues_content").hide("fade", { direction: "left" }, 150, function(){
    $(".issues_content").after(form);
    $('select#issue_assignee_id').chosen();
    $('select#issue_milestone_id').chosen();
    $("#edit_issue_dialog").show("fade", { direction: "right" }, 150);
    $('.add_new').hide();
  });
}

function switchFromNewIssue(){
  backToIssues();
}

function switchFromEditIssue(){
  backToIssues();
}

function backToIssues(){
  $("#edit_issue_dialog, #new_issue_dialog").hide("fade", { direction: "right" }, 150, function(){
    $(".issues_content").show("fade", { direction: "left" }, 150, function() { 
      $("#edit_issue_dialog").remove();
      $("#new_issue_dialog").remove();
      $('.add_new').show();
    });
  });
}

function initIssuesSearch() { 
  var href       = $('.issue_search').parent().attr('action');
  var last_terms = '';

  $('.issue_search').keyup(function() {
    var terms       = $(this).val();
    var milestone_id  = $('#milestone_id').val();
    var status      = $('#status').val();

    if (terms != last_terms) {
      last_terms = terms;

      if (terms.length >= 2 || terms.length == 0) {
        $.get(href, { 'f': status, 'terms': terms, 'milestone_id': milestone_id }, function(response) {
          $('#issues-table').html(response);
          setSortable();
        });
      }
    }
  });

  $('.delete-issue').live('ajax:success', function() {
    $(this).closest('tr').fadeOut(); updatePage();
  });
}
