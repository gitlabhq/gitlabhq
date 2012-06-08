var MergeRequest = {
  diffs_loaded: false,
  commits_loaded: false,
  opts: false,

  init:
    function(opts) {
      var self = this;
      self.opts = opts;

      self.showState(self.opts.current_state);
      if($(".automerge_widget").length && self.opts.check_enable){
        $.get(opts.url_to_automerge_check, function(data){
          self.showState(data.state);
        }, "json");
      }

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

      $(".line_note_link, .line_note_reply_link").live("click", function(e) {
        var form = $(".per_line_form");
        $(this).parent().parent().after(form);
        form.find("#note_line_code").val($(this).attr("line_code"));
        form.show();
        return false;
      });

      $(".edit_merge_request").live("ajax:beforeSend", function() {
        $(this).replaceWith('#{image_tag "ajax_loader.gif"}');
      });

      $(".mr_show_all_commits").live("click", function(e) {
          MergeRequest.showAllCommits();
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
        $(".automerge_widget.already_cannot_be_merged").show();
    }
};
