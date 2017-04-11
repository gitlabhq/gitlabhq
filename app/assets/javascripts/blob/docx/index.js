import JSZip from 'jszip';
import JSZipUtils from 'jszip-utils';
import DocX from './docx';

export default class DocxRenderer {
  constructor(container) {
    this.el = container;
    this.loader = this.el.querySelector('i');
    this.endpoint = this.el.dataset.endpoint;
    this.loadFile();
    this.loader.style = 'display:none;';
    this
  }

  loadFile(file) {
    return this.getZipFile()
      .then(data => {
        return JSZip.loadAsync(data)
      })
      .then(asyncResult => {
        return asyncResult.files['word/document.xml'].async('string')
      })
      .then((content) => {
        const $xml = $($.parseXML(content));
        const $textNodes = $xml.find('t');
        $textNodes.each((i, el) => {
          const p = document.createElement('p');
          p.innerText = $(el).text();
          this.el.appendChild(p);
        })
      })
      .catch(this.error.bind(this));
  }

  error(e) {
    console.log(e)
    const errorMsg = document.createElement('p');

    errorMsg.className = 'prepend-top-default append-bottom-default text-center';
    errorMsg.textContent = 'Cannot show preview.';
    this.el.appendChild(errorMsg);
  }

  getZipFile() {
    return new JSZip.external.Promise((resolve, reject) => {
      JSZipUtils.getBinaryContent(this.el.dataset.endpoint, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data);
        }
      });
    });
  }

  renderFile(e) {
    console.log('renderFile', e.target.response)
  }
}