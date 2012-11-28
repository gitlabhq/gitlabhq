var MergeRequest = { 
  diffs_loaded: false,
  commits_loaded: false,
  opts: false,

  init:
    function(opts) {
      var self = this;
      self.opts = opts;

      self.initTabs();
      self.initMergeWidget();

      $(".mr-show-all-commits").bind("click", function() { 
        self.showAllCommits();
      });

      $(".line-note-link, .line-note-reply-link").live("click", function(e) {
        var form = $(".per-line-form");
        $(this).parent().parent().after(form);
        form.find("#note_line_code").val($(this).attr("line_code"));
        form.show();
        return false;
      });
    },

  initMergeWidget: 
    function() { 
      var self = this;
      self.showState(self.opts.current_state);

      if($(".automerge-widget").length && self.opts.check_enable){
        $.get(self.opts.url_to_automerge_check, function(data){
          self.showState(data.state);
        }, "json");
      }
    },

  initTabs:
    function() { 
      $(".mr-nav-tabs a").live("click", function() { 
        $(".mr-nav-tabs a").parent().removeClass("active");
        $(this).parent().addClass("active");
      });

      var current_tab;
      if(this.opts.action == "diffs") { 
        current_tab = $(".mr-nav-tabs .merge-diffs-tab");
      } else {
        current_tab = $(".mr-nav-tabs .merge-notes-tab");
      }
      current_tab.parent().addClass("active");

      this.initNotesTab();
      this.initDiffTab();
    },

  initNotesTab: 
    function() { 
      $(".mr-nav-tabs a.merge-notes-tab").live("click", function(e) { 
        $(".merge-request-diffs").hide();
        $(".merge-request-notes").show();
        var mr_path = $(".merge-notes-tab").attr("data-url");
        history.pushState({ path: mr_path }, '', mr_path);
        e.preventDefault();
      });
    },

  initDiffTab: 
    function() { 
      $(".mr-nav-tabs a.merge-diffs-tab").live("click", function(e) { 
        if(!MergeRequest.diffs_loaded) { 
          MergeRequest.loadDiff(); 
        }
        $(".merge-request-notes").hide();
        $(".merge-request-diffs").show();
        var mr_diff_path = $(".merge-diffs-tab").attr("data-url");
        history.pushState({ path: mr_diff_path }, '', mr_diff_path);
        e.preventDefault();
      });

    },

  showState:
    function(state){
      $(".automerge-widget").hide();
      $(".automerge-widget." + state).show();
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
          $(".merge-request-notes").hide();
          $('.status').removeClass("loading");
        },
        dataType: "script"});
    }, 

  showAllCommits: 
    function() { 
      $(".first-mr-commits").remove();
      $(".all-mr-commits").removeClass("hide");
    },

  already_cannot_be_merged:
    function(){
        $(".automerge-widget").hide();
        $(".merge-in-progress").hide();
        $(".automerge-widget.already-cannot-be-merged").show();
    }
};

/*
 * Filter merge requests
 */
function merge_requestsPage() {
  $("#assignee_id").chosen();
  $("#milestone_id").chosen();
  $("#milestone_id, #assignee_id").on("change", function(){
    $(this).closest("form").submit();
  });
}
