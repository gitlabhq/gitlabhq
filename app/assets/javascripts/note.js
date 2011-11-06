var NoteList = { 

first_id: 0,
last_id: 0,
resource_name: null,

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
    this.first_id = id;
    $("#notes-list").append(html);
    this.initLoadMore();
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
    $(window).bind('scroll', function(){
      if($(window).scrollTop() == $(document).height() - $(window).height()){
        $(window).unbind('scroll');
        NoteList.getOld();
      }
    });
  }
}
