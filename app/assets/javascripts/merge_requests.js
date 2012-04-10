var MergeRequest = { 
  diffs_loaded: false,
  commits_loaded: false,

  init:
    function() { 
      $(".nav-tabs a").live("click", function() { 
        $(".nav-tabs a").parent().removeClass("active");
        $(this).parent().addClass("active");
      });

      $(".nav-tabs a.merge-notes-tab").live("click", function(e) { 
        $(".merge-request-diffs").hide();
        $(".merge_request_notes").show();
        e.preventDefault();
      });

      $(".nav-tabs a.merge-diffs-tab").live("click", function(e) { 
        if(!MergeRequest.diffs_loaded) { 
          MergeRequest.loadDiff(); 
        }
        $(".merge_request_notes").hide();
        $(".merge-request-diffs").show();
        e.preventDefault();
      });
    },

  loadDiff:
    function() { 
      $(".dashboard-loader").show();
      $.ajax({
        type: "GET",
        url: $(".merge-diffs-tab").attr("data-url"),
        beforeSend: function(){ $('.status').addClass("loading")},
        complete: function(){ 
          MergeRequest.diffs_loaded = true;
          $(".merge_request_notes").hide();
          $('.status').removeClass("loading");
        },
        dataType: "script"});
    }
}
