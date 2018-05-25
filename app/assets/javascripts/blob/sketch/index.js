import JSZip from 'jszip';
import JSZipUtils from 'jszip-utils';

export default class SketchLoader {
  constructor(container) {
    this.container = container;
    this.loadingIcon = this.container.querySelector('.js-loading-icon');

    this.load();
  }

  load() {
    return this.getZipFile()
      .then(data => JSZip.loadAsync(data))
      .then(asyncResult => asyncResult.files['previews/preview.png'].async('uint8array'))
      .then((content) => {
        const url = window.URL || window.webkitURL;
        const blob = new Blob([new Uint8Array(content)], {
          type: 'image/png',
        });
        const previewUrl = url.createObjectURL(blob);

        this.render(previewUrl);
      })
      .catch(this.error.bind(this));
  }

  getZipFile() {
    return new JSZip.external.Promise((resolve, reject) => {
      JSZipUtils.getBinaryContent(this.container.dataset.endpoint, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data);
        }
      });
    });
  }

  render(previewUrl) {
    const previewLink = document.createElement('a');
    const previewImage = document.createElement('img');

    previewLink.href = previewUrl;
    previewLink.target = '_blank';
    previewImage.src = previewUrl;
    previewImage.className = 'img-fluid';

    previewLink.appendChild(previewImage);
    this.container.appendChild(previewLink);

    this.removeLoadingIcon();
  }

  error() {
    const errorMsg = document.createElement('p');

    errorMsg.className = 'prepend-top-default append-bottom-default text-center';
    errorMsg.textContent = `
      Cannot show preview. For previews on sketch files, they must have the file format
      introduced by Sketch version 43 and above.
    `;
    this.container.appendChild(errorMsg);

    this.removeLoadingIcon();
  }

  removeLoadingIcon() {
    if (this.loadingIcon) {
      this.loadingIcon.remove();
    }
  }
}
