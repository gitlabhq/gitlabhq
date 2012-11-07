var NoteList = {

  notes_path: null,
  target_params: null,
  target_id: 0,
  target_type: null,
  top_id: 0,
  bottom_id: 0,
  loading_more_disabled: false,
  reversed: false,

  init:
    function(tid, tt, path) {
      this.notes_path = path + ".js";
      this.target_id = tid;
      this.target_type = tt;
      this.reversed = $("#notes-list").hasClass("reversed");
      this.target_params = "&target_type=" + this.target_type + "&target_id=" + this.target_id;

      // get initial set of notes
      this.getContent();

      $("#notes-list, #new-notes-list").on("ajax:success", ".delete-note", function() {
        $(this).closest('li').fadeOut(function() {
          $(this).remove();
          NoteList.updateVotes();
        });
      });

      $(".note-form-holder").on("ajax:before", function(){
        $(".submit_note").disable();
      })

      $(".note-form-holder").on("ajax:complete", function(){
        $(".submit_note").enable();
      })

      disableButtonIfEmptyField(".note-text", ".submit_note");

      $("#note_attachment").change(function(e){
        var val = $('.input-file').val();
        var filename = val.replace(/^.*[\\\/]/, '');
        $(".file_name").text(filename);
      });

      if(this.reversed) {
        var textarea = $(".note-text");
        $('.note_advanced_opts').hide();
        textarea.css("height", "40px");
        textarea.on("focus", function(){
          $(this).css("height", "80px");
          $('.note_advanced_opts').show();
        });
      }
    },


  /**
   * Handle loading the initial set of notes.
   * And set up loading more notes when scrolling to the bottom of the page.
   */


  /**
   * Gets an inital set of notes.
   */
  getContent:
    function() {
      $.ajax({
        type: "GET",
      url: this.notes_path,
      data: "?" + this.target_params,
      complete: function(){ $('.notes-status').removeClass("loading")},
      beforeSend: function() { $('.notes-status').addClass("loading") },
      dataType: "script"});
    },

  /**
   * Called in response to getContent().
   * Replaces the content of #notes-list with the given html.
   */
  setContent:
    function(first_id, last_id, html) {
      this.top_id = first_id;
      this.bottom_id = last_id;
      $("#notes-list").html(html);

      // init infinite scrolling
      this.initLoadMore();

      // init getting new notes
      if (this.reversed) {
        this.initRefreshNew();
      }
    },


  /**
   * Handle loading more notes when scrolling to the bottom of the page.
   * The id of the last note in the list is in this.bottom_id.
   *
   * Set up refreshing only new notes after all notes have been loaded.
   */


  /**
   * Initializes loading more notes when scrolling to the bottom of the page.
   */
  initLoadMore:
    function() {
      $(document).endlessScroll({
        bottomPixels: 400,
        fireDelay: 1000,
        fireOnce:true,
        ceaseFire: function() {
          return NoteList.loading_more_disabled;
        },
        callback: function(i) {
          NoteList.getMore();
        }
      });
    },

  /**
   * Gets an additional set of notes.
   */
  getMore:
    function() {
      // only load more notes if there are no "new" notes
      $('.loading').show();
      $.ajax({
        type: "GET",
        url: this.notes_path,
        data: "loading_more=1&" + (this.reversed ? "before_id" : "after_id") + "=" + this.bottom_id + this.target_params,
        complete: function(){ $('.notes-status').removeClass("loading")},
        beforeSend: function() { $('.notes-status').addClass("loading") },
        dataType: "script"});
    },

  /**
   * Called in response to getMore().
   * Append notes to #notes-list.
   */
  appendMoreNotes:
    function(id, html) {
      if(id != this.bottom_id) {
        this.bottom_id = id;
        $("#notes-list").append(html);
      }
    },

  /**
   * Called in response to getMore().
   * Disables loading more notes when scrolling to the bottom of the page.
   * Initalizes refreshing new notes.
   */
  finishedLoadingMore:
    function() {
      this.loading_more_disabled = true;

      // from now on only get new notes
      if (!this.reversed) {
        this.initRefreshNew();
      }
      // make sure we are up to date
      this.updateVotes();
    },


  /**
   * Handle refreshing and adding of new notes.
   *
   * New notes are all notes that are created after the site has been loaded.
   * The "old" notes are in #notes-list the "new" ones will be in #new-notes-list.
   * The id of the last "old" note is in this.bottom_id.
   */


  /**
   * Initializes getting new notes every n seconds.
   */
  initRefreshNew:
    function() {
      setInterval("NoteList.getNew()", 10000);
    },

  /**
   * Gets the new set of notes.
   */
  getNew:
    function() {
      $.ajax({
        type: "GET",
      url: this.notes_path,
      data: "loading_new=1&after_id=" + (this.reversed ? this.top_id : this.bottom_id) + this.target_params,
      dataType: "script"});
    },

  /**
   * Called in response to getNew().
   * Replaces the content of #new-notes-list with the given html.
   */
  replaceNewNotes:
    function(html) {
      $("#new-notes-list").html(html);
      this.updateVotes();
    },

  /**
   * Adds a single note to #new-notes-list.
   */
  appendNewNote:
    function(id, html) {
      if (this.reversed) {
        $("#new-notes-list").prepend(html);
      } else {
        $("#new-notes-list").append(html);
      }
      this.updateVotes();
    },

  /**
   * Recalculates the votes and updates them (if they are displayed at all).
   *
   * Assumes all relevant notes are displayed (i.e. there are no more notes to
   * load via getMore()).
   * Might produce inaccurate results when not all notes have been loaded and a
   * recalculation is triggered (e.g. when deleting a note).
   */
  updateVotes:
    function() {
      var votes = $("#votes .votes");
      var notes = $("#notes-list, #new-notes-list").find(".note .vote");

      // only update if there is a vote display
      if (votes.size()) {
        var upvotes = notes.filter(".upvote").size();
        var downvotes = notes.filter(".downvote").size();
        var votesCount = upvotes + downvotes;
        var upvotesPercent = votesCount ? (100.0 / votesCount * upvotes) : 0;
        var downvotesPercent = votesCount ? (100.0 - upvotesPercent) : 0;

        // change vote bar lengths
        votes.find(".bar-success").css("width", upvotesPercent+"%");
        votes.find(".bar-danger").css("width", downvotesPercent+"%");
        // replace vote numbers
        votes.find(".upvotes").text(votes.find(".upvotes").text().replace(/\d+/, upvotes));
        votes.find(".downvotes").text(votes.find(".downvotes").text().replace(/\d+/, downvotes));
      }
    }
};

var PerLineNotes = {
  init:
    function() {
      /**
       * Called when clicking on the "add note" or "reply" button for a diff line.
       *
       * Shows the note form below the line.
       * Sets some hidden fields in the form.
       */
      $(".diff_file_content").on("click", ".line_note_link, .line_note_reply_link", function(e) {
        var form = $(".per_line_form");
        $(this).closest("tr").after(form);
        form.find("#note_line_code").val($(this).data("lineCode"));
        form.show();
        return false;
      });

      disableButtonIfEmptyField(".line-note-text", ".submit_inline_note");

      /**
       * Called in response to successfully deleting a note on a diff line.
       *
       * Removes the actual note from view.
       * Removes the reply button if the last note for that line has been removed.
       */
      $(".diff_file_content").on("ajax:success", ".delete-note", function() {
        var trNote = $(this).closest("tr");
        trNote.fadeOut(function() {
          $(this).remove();
        });

        // check if this is the last note for this line
        // elements must really be removed for this to work reliably
        var trLine = trNote.prev();
        var trRpl  = trNote.next();
        if (trLine.hasClass("line_holder") && trRpl.hasClass("reply")) {
          trRpl.fadeOut(function() { $(this).remove(); });
        }
      });
    }
}
