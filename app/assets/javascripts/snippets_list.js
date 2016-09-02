(function() {
  this.gl.SnippetsList = function() {
    $('.snippets-list-holder .pagination').on('ajax:success', function(e, data) {
      $('.snippets-list-holder').replaceWith(data.html);
    });
  };
}).call(this);
