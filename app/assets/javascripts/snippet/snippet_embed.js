export default () => {
  const { protocol, host, pathname } = location;
  const shareBtn = document.querySelector('#share-btn');
  const embedBtn = document.querySelector('#embed-btn');
  const snippetUrlArea = document.querySelector('#snippet-url-area');
  const embedAction = document.querySelector('#embed-action');

  shareBtn.addEventListener('click', (event) => {
    shareBtn.classList.add('is-active');
    embedBtn.classList.remove('is-active');
    snippetUrlArea.value = `${protocol}//${host + pathname}`;
    embedAction.innerHTML = 'Share';
  });

  embedBtn.addEventListener('click', (event) => {
    embedBtn.classList.add('is-active');
    shareBtn.classList.remove('is-active');
    const scriptTag = `<script src="${protocol}//${host + pathname}.js"></script>`;
    snippetUrlArea.value = scriptTag;
    embedAction.innerHTML = 'Embed';
  });
};
