import JSZip from 'jszip';
import JSZipUtils from 'jszip-utils';
import Docx from './docx';

export default class DocxRenderer {
  constructor(container) {
    this.el = container;
    this.loader = this.el.querySelector('i');
    this.endpoint = this.el.dataset.endpoint;
    this.loadFile();
    this.loader.style = 'display:none;';
  }

  loadFile(file) {
    return this.getZipFile()
      .then(data => {
        return JSZip.loadAsync(data)
      })
      .then(asyncResult => {
        this.asyncResult = asyncResult;
        return asyncResult.files['word/document.xml'].async('string')
      })
      .then((content) => {
        this.docx = new Docx(content);
        return this.asyncResult.files['word/styles.xml'].async('string');
      })
      .then((content) => {
        this.docx.setStyles(content);
        return this.asyncResult.files['word/_rels/document.xml.rels'].async('string');
      })
      .then((content) => {
        this.docx.setRelationships(content);
        this.el.appendChild(this.docx.parseDoc());
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