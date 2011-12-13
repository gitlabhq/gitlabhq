var MergeRequest = { 
  diff_loaded: false,
  commits_loaded: false,

  init:
    function() { 
      $(".merge-tabs a").live("click", function() { 
        $(".merge-tabs a").removeClass("active");
        $(this).addClass("active");
      });

      $(".merge-tabs a.merge-commits-tab").live("click", function() { 
        if(MergeRequest.commits_loaded) { 
          $(".merge-request-commits").show();
        } else { 
          MergeRequest.loadCommits(); 
        }
      });
    },

  loadCommits:
    function() { 
      $(".dashboard-loader").show();
      $.ajax({
        type: "GET",
        url: location.href + "/commits",
        complete: function(){ 
          MergeRequest.commits_loaded = true;
          $(".dashboard-loader").hide()},
        dataType: "script"});
    },

  loadDiff:
    function() { 
    }
}
