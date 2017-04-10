/* global Flash */

import sqljs from 'sql.js';

class BalsamiqViewer {
  constructor(viewer) {
    this.viewer = viewer;
    this.endpoint = this.viewer.dataset.endpoint;
  }

  loadFile() {
    const xhr = new XMLHttpRequest();

    xhr.open('GET', this.endpoint, true);
    xhr.responseType = 'arraybuffer';

    xhr.onload = this.renderFile.bind(this);
    xhr.onerror = BalsamiqViewer.onError;

    xhr.send();
  }

  renderFile(loadEvent) {
    const container = document.createElement('ul');

    this.initDatabase(loadEvent.target.response);

    const previews = this.getPreviews();
    const renderedPreviews = previews.map(preview => this.renderPreview(preview, container));

    container.innerHTML = renderedPreviews.join('');
    container.classList.add('list-inline');

    this.viewer.appendChild(container);
  }

  initDatabase(data) {
    const previewBinary = new Uint8Array(data);

    this.database = new sqljs.Database(previewBinary);
  }

  getPreviews() {
    const thumnails = this.database.exec('SELECT * FROM thumbnails');

    return thumnails[0].values.map(BalsamiqViewer.parsePreview);
  }

  renderPreview(preview) {
    const previewElement = document.createElement('li');

    previewElement.innerHTML = this.renderTemplate(preview);

    return previewElement.outerHTML;
  }

  renderTemplate(preview) {
    let template = BalsamiqViewer.PREVIEW_TEMPLATE;

    const title = this.database.exec(`SELECT * FROM resources WHERE id = '${preview.resourceID}'`);
    const name = JSON.parse(title[0].values[0][2]).name;
    const image = preview.image;

    template = template.replace(/{{name}}/, name).replace(/{{image}}/, image);

    return template;
  }

  static parsePreview(preview) {
    return JSON.parse(preview[1]);
  }

  static onError() {
    const flash = new Flash('Balsamiq file could not be loaded.');

    return flash;
  }
}

BalsamiqViewer.PREVIEW_TEMPLATE = `
  <div class="panel panel-default">
    <div class="panel-heading">{{name}}</div>
    <div class="panel-body">
      <img class="img-thumbnail" src="data:image/png;base64,{{image}}"/>
    </div>
  </div>
`;

export default BalsamiqViewer;
