function SnippetsList() {
  const $holder = $('.snippets-list-holder');

  $holder.find('.pagination').on('ajax:success', (e, data) => {
    $holder.replaceWith(data.html);
  });
}

window.gl.SnippetsList = SnippetsList;
