export default () => {
  const { protocol, host, pathname } = location;
  const shareBtn = document.querySelector('#share-btn');
  const embedBtn = document.querySelector('#embed-btn');
  const snippetUrlArea = document.querySelector('#snippet-url-area');
  const embedAction = document.querySelector('#embed-action');
  const url = `${protocol}//${host + pathname}`;

  shareBtn.addEventListener('click', () => {
    shareBtn.classList.add('is-active');
    embedBtn.classList.remove('is-active');
    snippetUrlArea.value = url;
    embedAction.innerText = 'Share';
  });

  embedBtn.addEventListener('click', () => {
    embedBtn.classList.add('is-active');
    shareBtn.classList.remove('is-active');
    const scriptTag = `<script src="${url}.js"></script>`;
    snippetUrlArea.value = scriptTag;
    embedAction.innerText = 'Embed';
  });
};
