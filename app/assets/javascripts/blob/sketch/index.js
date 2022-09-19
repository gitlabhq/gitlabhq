import JSZip from 'jszip';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export default class SketchLoader {
  constructor(container) {
    this.container = container;
    this.loadingIcon = this.container.querySelector('.js-loading-icon');

    this.load().catch(() => {
      this.error();
    });
  }

  async load() {
    const zipContents = await this.getZipContents();
    const previewContents = await zipContents.files['previews/preview.png'].async('uint8array');

    const blob = new Blob([previewContents], {
      type: 'image/png',
    });

    this.render(window.URL.createObjectURL(blob));
  }

  async getZipContents() {
    const { data } = await axios.get(this.container.dataset.endpoint, {
      responseType: 'arraybuffer',
    });

    return JSZip.loadAsync(data);
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

    errorMsg.className = 'gl-mt-3 gl-mb-3 text-center';
    errorMsg.textContent = __(`
      Cannot show preview. For previews on sketch files, they must have the file format
      introduced by Sketch version 43 and above.
    `);
    this.container.appendChild(errorMsg);

    this.removeLoadingIcon();
  }

  removeLoadingIcon() {
    if (this.loadingIcon) {
      this.loadingIcon.remove();
    }
  }
}
