export default function UsagePing() {
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
