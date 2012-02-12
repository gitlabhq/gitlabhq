var CommitsList = {
  ref:null,
  limit:0,
  offset:0,
  disable:false,

  init:
    function(ref, limit) {
      $(".day-commits-table li.commit").live('click', function(e){
        if(e.target.nodeName != "A") {
          location.href = $(this).attr("url");
          e.stopPropagation();
          return false;
        }
      });

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
          return CommitsList.disable;
        },
        callback: function(i) {
          CommitsList.getOld();
        }
      });
    }
}
