function switchToNewIssue(form){
  $(".issues_content").hide("fade", { direction: "left" }, 150, function(){
    $(".issues_content").after(form);
    $('select#issue_assignee_id').chosen();
    $('select#issue_milestone_id').chosen();
    $("#new_issue_dialog").show("fade", { direction: "right" }, 150);
    $('.top-tabs .add_new').hide();
    disableButtonIfEmptyField("#issue_title", ".save-btn");
    setupGfmAutoComplete();
  });
}

function switchToEditIssue(form){
  $(".issues_content").hide("fade", { direction: "left" }, 150, function(){
    $(".issues_content").after(form);
    $('select#issue_assignee_id').chosen();
    $('select#issue_milestone_id').chosen();
    $("#edit_issue_dialog").show("fade", { direction: "right" }, 150);
    $('.add_new').hide();
    disableButtonIfEmptyField("#issue_title", ".save-btn");
    setupGfmAutoComplete();
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
        });
      }
    }
  });

  $('.delete-issue').live('ajax:success', function() {
    $(this).closest('tr').fadeOut(); updatePage();
  });
}

/**
 * Init issues page
 *
 */
function issuesPage(){ 
  initIssuesSearch();
  $("#update_status").chosen();
  $("#update_assignee_id").chosen();
  $("#update_milestone_id").chosen();

  $("#label_name").chosen();
  $("#assignee_id").chosen();
  $("#milestone_id").chosen();
  $("#milestone_id, #assignee_id, #label_name").on("change", function(){
    $(this).closest("form").submit();
  });

  $("#new_issue_link").click(function(){
    updateNewIssueURL();
  });

  $('body').on('ajax:success', '.close_issue, .reopen_issue, #new_issue', function(){
    var t = $(this),
        totalIssues,
        reopen = t.hasClass('reopen_issue'),
        newIssue = false;
    if( this.id == 'new_issue' ){
      newIssue = true;
    }
    $('.issue_counter, #new_issue').each(function(){
      var issue = $(this);
      totalIssues = parseInt( $(this).html(), 10 );

      if( newIssue || ( reopen && issue.closest('.main_menu').length ) ){
        $(this).html( totalIssues+1 );
      }else {
        $(this).html( totalIssues-1 );
      }
    });

  });

  $(".check_all_issues").click(function () {
    $('.selected_issue').attr('checked', this.checked);
    issuesCheckChanged();
  });

  $('.selected_issue').bind('change', issuesCheckChanged);
}

function issuesCheckChanged() { 
  var checked_issues = $('.selected_issue:checked');

  if(checked_issues.length > 0) { 
    var ids = []
    $.each(checked_issues, function(index, value) {
      ids.push($(value).attr("data-id"));
    })
    $('#update_issues_ids').val(ids);
    $('.issues_filters').hide();
    $('.issues_bulk_update').show();
  } else { 
    $('#update_issues_ids').val([]);
    $('.issues_bulk_update').hide();
    $('.issues_filters').show();
  }
}

function updateNewIssueURL(){
  var new_issue_link = $("#new_issue_link");
  var milestone_id = $("#milestone_id").val();
  var assignee_id = $("#assignee_id").val();
  var new_href = "";
  if(milestone_id){
    new_href = "issue[milestone_id]=" + milestone_id + "&";
  }
  if(assignee_id){
    new_href = new_href + "issue[assignee_id]=" + assignee_id;
  }
  if(new_href.length){
    new_href = new_issue_link.attr("href") + "?" + new_href;
    new_issue_link.attr("href", new_href);
  }
};
