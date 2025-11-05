import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';

export async function copyGLQLNodeAsGFM(el) {
  const transform = (e) => {
    [...e.querySelectorAll('time[title]')].forEach((time) => {
      // eslint-disable-next-line no-param-reassign
      time.textContent = time.title;
    });
  };

  const div = document.createElement('div');
  div.appendChild(el.cloneNode(true));
  transform(div);

  const html = div.innerHTML;
  const markdown = await CopyAsGFM.nodeToGFM(el);

  const clipboardItem = new ClipboardItem({
    'text/plain': new Blob([markdown], { type: 'text/plain' }),
    'text/html': new Blob([html], { type: 'text/html' }),
  });

  // eslint-disable-next-line no-restricted-properties -- navigator.clipboard intentionally used here
  navigator.clipboard.write([clipboardItem]);
}
