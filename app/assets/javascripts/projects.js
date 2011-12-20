var ProjectsList = {
  limit:0,
  offset:0,

  init:
    function(limit) {
      this.limit=limit;
      this.offset=limit;
      this.initLoadMore();

      $('.project_search').keyup(function() {
        var terms = $(this).val();
        if (terms.length >= 2 || terms.length == 0) {
          url = $('.project_search').parent().attr('action');
          $.ajax({
            type: "GET",
            url: location.href,
            data: { 'terms': terms, 'replace': true  },
            dataType: "script"
          });
        }
      });
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

  replace:
    function(count, html) {
      $(".tile").html(html);
      if(count == ProjectsList.limit) {
        this.offset = count;
        this.initLoadMore();
      } else {
        this.offset = 0;
      }
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
