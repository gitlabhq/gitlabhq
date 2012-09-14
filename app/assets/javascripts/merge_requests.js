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

      $(".mr_show_all_commits").bind("click", function() { 
        self.showAllCommits();
      });

      $(".line_note_link, .line_note_reply_link").live("click", function(e) {
        var form = $(".per_line_form");
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

      if($(".automerge_widget").length && self.opts.check_enable){
        $.get(self.opts.url_to_automerge_check, function(data){
          self.showState(data.state);
        }, "json");
      }
    },

  initTabs:
    function() { 
      $(".mr_nav_tabs a").live("click", function() { 
        $(".mr_nav_tabs a").parent().removeClass("active");
        $(this).parent().addClass("active");
      });

      var current_tab;
      if(this.opts.action == "diffs") { 
        current_tab = $(".mr_nav_tabs .merge-diffs-tab");
      } else {
        current_tab = $(".mr_nav_tabs .merge-notes-tab");
      }
      current_tab.parent().addClass("active");

      this.initNotesTab();
      this.initDiffTab();
    },

  initNotesTab: 
    function() { 
      $(".mr_nav_tabs a.merge-notes-tab").live("click", function(e) { 
        $(".merge-request-diffs").hide();
        $(".merge_request_notes").show();
        var mr_path = $(".merge-notes-tab").attr("data-url");
        history.pushState({ path: mr_path }, '', mr_path);
        e.preventDefault();
      });
    },

  initDiffTab: 
    function() { 
      $(".mr_nav_tabs a.merge-diffs-tab").live("click", function(e) { 
        if(!MergeRequest.diffs_loaded) { 
          MergeRequest.loadDiff(); 
        }
        $(".merge_request_notes").hide();
        $(".merge-request-diffs").show();
        var mr_diff_path = $(".merge-diffs-tab").attr("data-url");
        history.pushState({ path: mr_diff_path }, '', mr_diff_path);
        e.preventDefault();
      });

    },

  showState:
    function(state){
      $(".automerge_widget").hide();
      $(".automerge_widget." + state).show();
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
    }, 

  showAllCommits: 
    function() { 
      $(".first_mr_commits").remove();
      $(".all_mr_commits").removeClass("hide");
    },

  already_cannot_be_merged:
    function(){
        $(".automerge_widget").hide();
        $(".merge_in_progress").hide();
        $(".automerge_widget.already_cannot_be_merged").show();
    }
}
