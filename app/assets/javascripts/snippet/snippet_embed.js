(() => {
  $(() => {
    const { protocol, host, pathname } = location;

    $('#share-btn').click((event) => {
      event.preventDefault();
      $('#share-btn').addClass('is-active');
      $('#embed-btn').removeClass('is-active');
      $('#snippet-url-area').val(`${protocol}//${host + pathname}`);
      $('#embed-action').html('Share');
    });

    $('#embed-btn').click((event) => {
      event.preventDefault();
      $('#embed-btn').addClass('is-active');
      $('#share-btn').removeClass('is-active');
      const scriptTag = `<script src="${protocol}//${host + pathname}.js"></script>`;
      $('#snippet-url-area').val(scriptTag);
      $('#embed-action').html('Embed');
    });
  });
}).call(window);
