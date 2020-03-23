export default () => {
  const highlightLineClass = 'hll';
  const contentBody = document.getElementById('content-body');
  const searchTerm = contentBody.querySelector('.js-search-input').value.toLowerCase();
  const blobs = contentBody.querySelectorAll('.blob-result');

  blobs.forEach(blob => {
    const lines = blob.querySelectorAll('.line');
    lines.forEach(line => {
      if (line.textContent.toLowerCase().includes(searchTerm)) {
        line.classList.add(highlightLineClass);
      }
    });
  });
};
