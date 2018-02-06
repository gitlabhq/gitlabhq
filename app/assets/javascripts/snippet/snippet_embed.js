(() => {
  $(() => {
    const { protocol, host, pathname } = location;

    $('#share-btn').click((event) => {
      event.preventDefault();
      $('#snippet-url-area').val(`${protocol}//${host + pathname}`);
      $('#embed-action').html('Share');
    });

    $('#embed-btn').click((event) => {
      event.preventDefault();
      const scriptTag = `<script src="${protocol}//${host + pathname}.js"></script>`;
      $('#snippet-url-area').val(scriptTag);
      $('#embed-action').html('Embed');
    });
  });
}).call(window);
