/* eslint-disable */
(global => {
  global.gl = global.gl || {};

  gl.ApplicationSettings = function() {
    var usage_data_url = $('.usage-data').data('endpoint');

    $.ajax({
      type: "GET",
      url: usage_data_url,
      dataType: "html",
      success: function (html) {
        $(".usage-data").html(html);
      }
    });
  }
})(window);
