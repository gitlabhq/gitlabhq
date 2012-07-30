var NoteList = {

notes_path: null,
target_params: null,
target_id: 0,
target_type: null,
first_id: 0,
last_id: 0,
disable:false,

init:
  function(tid, tt, path) {
    this.notes_path = path + ".js";
    this.target_id = tid;
    this.target_type = tt;
    this.target_params = "&target_type=" + this.target_type + "&target_id=" + this.target_id;

    // get notes
    this.getContent();

    // get new notes every n seconds
    this.initRefresh();

    $('.delete-note').live('ajax:success', function() {
      $(this).closest('li').fadeOut(); });

    $("#new_note").live("ajax:before", function(){
      $(".submit_note").attr("disabled", "disabled");
    })

    $("#new_note").live("ajax:complete", function(){
      $(".submit_note").removeAttr("disabled");
    })

    $("#note_note").live("focus", function(){
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
 * Load new notes to fresh list called 'new_notes_list': 
 * - Replace 'new_notes_list' with new list every n seconds
 * - Append new notes to this list after submit
 */

initRefresh:
  function() {
    // init timer
    var intNew = setInterval("NoteList.getNew()", 10000);
  },

replace:
  function(html) {
    $("#new_notes_list").html(html);
  },

prepend:
  function(id, html) {
    if(id != this.last_id) {
      $("#new_notes_list").prepend(html);
    }
  },

getNew:
  function() {
    // refersh notes list
    $.ajax({
      type: "GET",
      url: this.notes_path,
      data: "last_id=" + this.last_id + this.target_params,
      dataType: "script"});
  },

refresh:
  function() {
    // refersh notes list
    $.ajax({
      type: "GET",
      url: this.notes_path,
      data: "first_id=" + this.first_id + "&last_id=" + this.last_id + this.target_params,
      dataType: "script"});
  },


/**
 * Init load of notes: 
 * 1. Get content with ajax call
 * 2. Set content of notes list with loaded one
 */


getContent: 
  function() { 
    $.ajax({
      type: "GET",
      url: this.notes_path,
      data: "?" + this.target_params,
      complete: function(){ $('.status').removeClass("loading")},
      beforeSend: function() { $('.status').addClass("loading") },
      dataType: "script"});
  },

setContent:
  function(fid, lid, html) {
      this.last_id = lid;
      this.first_id = fid;
      $("#notes-list").html(html);

      // Init infinite scrolling
      this.initLoadMore();
  },


/**
 * Paging for old notes when scroll to bottom: 
 * 1. Init scroll events with 'initLoadMore'
 * 2. Load onlder notes with 'getOld' method
 * 3. append old notes to bottom of list with 'append'
 *
 */


getOld:
  function() {
    $('.loading').show();
    $.ajax({
      type: "GET",
      url: this.notes_path,
      data: "first_id=" + this.first_id + this.target_params,
      complete: function(){ $('.status').removeClass("loading")},
      beforeSend: function() { $('.status').addClass("loading") },
      dataType: "script"});
  },

append:
  function(id, html) {
    if(this.first_id == id) { 
      this.disable = true;
    } else { 
      this.first_id = id;
      $("#notes-list").append(html);
    }
  },


initLoadMore:
  function() {
    $(document).endlessScroll({
      bottomPixels: 400,
      fireDelay: 1000,
      fireOnce:true,
      ceaseFire: function() { 
        return NoteList.disable;
      },
      callback: function(i) {
        NoteList.getOld();
      }
   });
  }
}
