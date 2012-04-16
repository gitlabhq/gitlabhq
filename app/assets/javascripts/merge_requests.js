var MergeRequest = { 
  diffs_loaded: false,
  commits_loaded: false,
  opts: false,

  init:
    function(opts) {
      this.opts = opts;

      if($(".automerge_widget").lenght){
        $.get(opts.url_to_automerge_check, function(data){
          $(".automerge_widget").hide();
          $(".automerge_widget." + data.state).show();
        }, "json");
      }

      $(".tabs a").live("click", function() { 
        $(".tabs a").parent().removeClass("active");
        $(this).parent().addClass("active");
      });

      $(".tabs a.merge-notes-tab").live("click", function(e) { 
        $(".merge-request-diffs").hide();
        $(".merge_request_notes").show();
        e.preventDefault();
      });

      $(".tabs a.merge-diffs-tab").live("click", function(e) { 
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
