function switchToNewIssue(form){
  $("#issues-table-holder").hide("slide", { direction: "left" }, 150, function(){
    $(".project-content").append(form);
    $('select#issue_assignee_id').chosen();
    $("#new_issue_dialog").show("slide", { direction: "right" }, 150);
    $('.top-tabs .add_new').hide();
  });
}

function switchToEditIssue(form){
  $("#issues-table-holder").hide("slide", { direction: "left" }, 150, function(){
    $(".project-content").append(form);
    $('select#issue_assignee_id').chosen();
    $("#edit_issue_dialog").show("slide", { direction: "right" }, 150);
    $('.top-tabs .add_new').hide();
  });
}

function switchFromNewIssue(){
  backToIssues();
}

function switchFromEditIssue(){
  backToIssues();
}

function backToIssues(){
  $("#edit_issue_dialog, #new_issue_dialog").hide("slide", { direction: "right" }, 150, function(){
    $("#issues-table-holder").show("slide", { direction: "left" }, 150, function() { 
      $("#edit_issue_dialog").remove();
      $("#new_issue_dialog").remove();
      $('.top-tabs .add_new').show();
    });
  });
}
