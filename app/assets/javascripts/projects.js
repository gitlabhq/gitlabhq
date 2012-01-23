var ProjectsList = {
  limit:0,
  offset:0,

  init:
    function(limit) {
      this.limit=limit;
      this.offset=limit;
      this.initLoadMore();
    },

  getOld:
    function() {
      $('.loading').show();
      $.ajax({
        type: "GET",
        url: location.href,
        data: "limit=" + this.limit + "&offset=" + this.offset,
        complete: function(){ $('.loading').hide()},
        dataType: "script"});
    },

  append:
    function(count, html) {
      $(".tile").append(html);
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
          $('.loading').show();
          ProjectsList.getOld();
        }
      });
    }
}
