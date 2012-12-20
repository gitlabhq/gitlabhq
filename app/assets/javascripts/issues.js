function initIssuesSearch() { 
  var href       = $('#issue_search_form').attr('action');
  var last_terms = '';

  $('#issue_search').keyup(function() {
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

  $('body').on('ajax:success', '.close_issue, .reopen_issue', function(){
    var t = $(this),
        totalIssues,
        reopen = t.hasClass('reopen_issue');
    $('.issue_counter').each(function(){
      var issue = $(this);
      totalIssues = parseInt( $(this).html(), 10 );

      if( reopen && issue.closest('.main_menu').length ){
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
