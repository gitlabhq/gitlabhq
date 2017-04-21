function UsagePing() {
  const usageDataUrl = $('.usage-data').data('endpoint');

  $.ajax({
    type: 'GET',
    url: usageDataUrl,
    dataType: 'html',
    success(html) {
      $('.usage-data').html(html);
    },
  });
}

window.gl = window.gl || {};
window.gl.UsagePing = UsagePing;
