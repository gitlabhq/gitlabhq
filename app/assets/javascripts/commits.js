$(document).ready(function(){
  $(".day-commits-table li.commit").live('click', function(e){
    if(e.target.nodeName != "A") {
      location.href = $(this).attr("url");
      e.stopPropagation();
      return false;
    }
  });
});



var CommitsList = { 

ref:null,
limit:0,
offset:0,

init: 
  function(ref, limit) { 
    this.ref=ref; 
    this.limit=limit; 
    this.offset=limit; 
    this.initLoadMore();
    $('.loading').show();
  },

getOld:
  function() { 
    $('.loading').show();
    $.ajax({
      type: "GET",
      url: location.href,
      data: "limit=" + this.limit + "&offset=" + this.offset + "&ref=" + this.ref,
      complete: function(){ $('.loading').hide()},
      dataType: "script"});
  },

append:
  function(count, html) {
    $("#commits_list").append(html);
    if(count > 0) { 
      this.offset += count;
      this.initLoadMore();
    }  
  },

initLoadMore:
  function() { 
    $(window).bind('scroll', function(){
      if($(window).scrollTop() == $(document).height() - $(window).height()){
        $(window).unbind('scroll');
        CommitsList.getOld();
      }
    });
  }
}
