var NoteList = {

  notes_path: null,
  target_params: null,
  target_id: 0,
  target_type: null,
  bottom_id: 0,
  loading_more_disabled: false,

  init:
    function(tid, tt, path) {
      this.notes_path = path + ".js";
      this.target_id = tid;
      this.target_type = tt;
      this.target_params = "&target_type=" + this.target_type + "&target_id=" + this.target_id;

      // get initial set of notes
      this.getContent();

      $('.delete-note').live('ajax:success', function() {
        $(this).closest('li').fadeOut(); });

      $(".note-form-holder").on("ajax:before", function(){
        $(".submit_note").disable()
      })

      $(".note-form-holder").on("ajax:complete", function(){
        $(".submit_note").enable()
      })

      disableButtonIfEmptyField(".note-text", ".submit_note");

      $(".note-text").on("focus", function(){
        $(this).css("height", "80px");
        $('.note_advanced_opts').show();
      });

      $("#note_attachment").change(function(e){
        var val = $('.input-file').val();
        var filename = val.replace(/^.*[\\\/]/, '');
        $(".file_name").text(filename);
      });
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
    function(last_id, html) {
      this.bottom_id = last_id;
      $("#notes-list").html(html);

      // Init infinite scrolling
      this.initLoadMore();
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
        data: "loading_more=1&after_id=" + this.bottom_id + this.target_params,
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
      this.initRefreshNew();
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
   * Gets the new set of notes (i.e. all notes after ).
   */
  getNew:
    function() {
      $.ajax({
        type: "GET",
      url: this.notes_path,
      data: "loading_new=1&after_id=" + this.bottom_id + this.target_params,
      dataType: "script"});
    },

  /**
   * Called in response to getNew().
   * Replaces the content of #new-notes-list with the given html.
   */
  replaceNewNotes:
    function(html) {
      $("#new-notes-list").html(html);
    },

  /**
   * Adds a single note to #new-notes-list.
   */
  appendNewNote:
    function(id, html) {
      if(id != this.bottom_id) {
        $("#new-notes-list").append(html);
      }
    }
};

var PerLineNotes = {
  init:
    function() {
      $(".line_note_link, .line_note_reply_link").on("click", function(e) {
        var form = $(".per_line_form");
        $(this).closest("tr").after(form);
        form.find("#note_line_code").val($(this).attr("line_code"));
        form.show();
        return false;
      });
      disableButtonIfEmptyField(".line-note-text", ".submit_inline_note");
    }
}
