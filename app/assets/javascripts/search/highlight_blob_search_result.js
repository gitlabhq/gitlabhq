export default (search = '') => {
  const highlightLineClass = 'hll';
  const contentBody = document.getElementById('content-body');
  const searchTerm = search.toLowerCase();
  const blobs = contentBody.querySelectorAll('.js-blob-result');

  blobs.forEach((blob) => {
    const lines = blob.querySelectorAll('.line');
    lines.forEach((line) => {
      if (line.textContent.toLowerCase().includes(searchTerm)) {
        line.classList.add(highlightLineClass);
      }
    });
  });
};
