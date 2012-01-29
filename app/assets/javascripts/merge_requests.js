var MergeRequest = { 
  diffs_loaded: false,
  commits_loaded: false,

  init:
    function() { 
      $(".tabs a").live("click", function() { 
        $(".tabs a").parent().removeClass("active");
        $(this).parent().addClass("active");
      });

      $(".tabs a.merge-notes-tab").live("click", function() { 
        $(".merge-request-commits, .merge-request-diffs").hide();
        $(".merge-request-notes").show();
      });

      $(".tabs a.merge-commits-tab").live("click", function() { 
        if(!MergeRequest.commits_loaded) { 
          MergeRequest.loadCommits(); 
        }
        $(".merge-request-notes, .merge-request-diffs").hide();
        $(".merge-request-commits").show();
      });

      $(".tabs a.merge-diffs-tab").live("click", function() { 
        if(!MergeRequest.diffs_loaded) { 
          MergeRequest.loadDiff(); 
        }
        $(".merge-request-notes, .merge-request-commits").hide();
        $(".merge-request-diffs").show();
      });
    },

  loadCommits:
    function() { 
      $(".dashboard-loader").show();
      $.ajax({
        type: "GET",
        url: $(".merge-commits-tab").attr("data-url"),
        complete: function(){ 
          MergeRequest.commits_loaded = true;
          $(".merge-request-notes, .merge-request-diffs").hide();
          $(".dashboard-loader").hide()},
        dataType: "script"});
    },

  loadDiff:
    function() { 
      $(".dashboard-loader").show();
      $.ajax({
        type: "GET",
        url: $(".merge-diffs-tab").attr("data-url"),
        complete: function(){ 
          MergeRequest.diffs_loaded = true;
          $(".merge-request-notes, .merge-request-commits").hide();
          $(".dashboard-loader").hide()},
        dataType: "script"});
    }
}
