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
    this.target_params = "&target_type=" + this.target_type + "&target_id=" + this.target_id
    this.refresh();
    this.initRefresh();
    this.initLoadMore();
  },

getOld:
  function() {
    $('.loading').show();
    $.ajax({
      type: "GET",
      url: this.notes_path,
      data: "first_id=" + this.first_id + this.target_params,
      complete: function(){ $('.loading').hide()},
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

replace:
  function(fid, lid, html) {
    this.first_id = fid;
    this.last_id = lid;
    $("#notes-list").html(html);
    this.initLoadMore();
  },

prepend:
  function(id, html) {
    if(id != this.last_id) {
      this.last_id = id;
      $("#notes-list").prepend(html);
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

initRefresh:
  function() {
    // init timer
    var intNew = setInterval("NoteList.getNew()", 15000);
    var intRefresh = setInterval("NoteList.refresh()", 90000);
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
