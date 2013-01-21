var Pager = {
  limit:0,
  offset:0,
  disable:false,

  init:
    function(limit, preload) {
      this.limit=limit;

      if(preload) { 
        this.offset = 0;
        this.getOld();
      } else { 
        this.offset = limit;
      }

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
      $(".content_list").append(html);
      if(count > 0) {
        this.offset += count;
      } else { 
        this.disable = true;
      }
    },

  initLoadMore:
    function() {
      $(document).endlessScroll({
        bottomPixels: 400,
        fireDelay: 1000,
        fireOnce:true,
        ceaseFire: function() { 
          return Pager.disable;
        },
        callback: function(i) {
          $('.loading').show();
          Pager.getOld();
        }
     });
    }
}
