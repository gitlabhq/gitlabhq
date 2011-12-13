var MergeRequest = { 
  diffs_loaded: false,
  commits_loaded: false,

  init:
    function() { 
      $(".merge-tabs a").live("click", function() { 
        $(".merge-tabs a").removeClass("active");
        $(this).addClass("active");
      });

      $(".merge-tabs a.merge-notes-tab").live("click", function() { 
        $(".merge-request-commits, .merge-request-diffs").hide();
        $(".merge-request-notes").show();
      });

      $(".merge-tabs a.merge-commits-tab").live("click", function() { 
        if(!MergeRequest.commits_loaded) { 
          MergeRequest.loadCommits(); 
        }
        $(".merge-request-notes, .merge-request-diffs").hide();
        $(".merge-request-commits").show();
      });

      $(".merge-tabs a.merge-diffs-tab").live("click", function() { 
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
