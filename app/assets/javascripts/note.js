var NoteList = {

first_id: 0,
last_id: 0,
resource_name: null,
disable:false,

init:
  function(resource_name, first_id, last_id) {
    this.resource_name = resource_name;
    this.first_id = first_id;
    this.last_id = last_id;
    this.initRefresh();
    this.initLoadMore();
  },

getOld:
  function() {
    $('.loading').show();
    $.ajax({
      type: "GET",
      url: location.href,
      data: "first_id=" + this.first_id,
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
      url: location.href,
      data: "last_id=" + this.last_id,
      dataType: "script"});
  },

refresh:
  function() {
    // refersh notes list
    $.ajax({
      type: "GET",
      url: location.href,
      data: "first_id=" + this.first_id + "&last_id=" + this.last_id,
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
