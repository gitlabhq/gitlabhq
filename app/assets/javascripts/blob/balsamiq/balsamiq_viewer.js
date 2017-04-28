/* global Flash */

import sqljs from 'sql.js';
import { template as _template } from 'underscore';

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

    this.spinner.start();

    xhr.send();
  }

  renderFile(loadEvent) {
    this.spinner.stop();

    const container = document.createElement('ul');

    this.initDatabase(loadEvent.target.response);

    const previews = this.getPreviews();
    const renderedPreviews = previews.map(preview => this.renderPreview(preview));

    container.innerHTML = renderedPreviews.join('');
    container.classList.add('list-inline', 'previews');

    this.viewer.appendChild(container);
  }

  initDatabase(data) {
    const previewBinary = new Uint8Array(data);

    this.database = new sqljs.Database(previewBinary);
  }

  getPreviews() {
    const thumbnails = this.database.exec('SELECT * FROM thumbnails');

    return thumbnails[0].values.map(BalsamiqViewer.parsePreview);
  }

  getTitle(resourceID) {
    return this.database.exec(`SELECT * FROM resources WHERE id = '${resourceID}'`);
  }

  renderPreview(preview) {
    const previewElement = document.createElement('li');

    previewElement.classList.add('preview');
    previewElement.innerHTML = this.renderTemplate(preview);

    return previewElement.outerHTML;
  }

  renderTemplate(preview) {
    const title = this.getTitle(preview.resourceID);
    const name = BalsamiqViewer.parseTitle(title);
    const image = preview.image;

    const template = BalsamiqViewer.PREVIEW_TEMPLATE({
      name,
      image,
    });

    return template;
  }

  static parsePreview(preview) {
    return JSON.parse(preview[1]);
  }

  static parseTitle(title) {
    return JSON.parse(title[0].values[0][2]).name;
  }

  static onError() {
    const flash = new Flash('Balsamiq file could not be loaded.');

    return flash;
  }
}

BalsamiqViewer.PREVIEW_TEMPLATE = _template(`
  <div class="panel panel-default">
    <div class="panel-heading"><%- name %></div>
    <div class="panel-body">
      <img class="img-thumbnail" src="data:image/png;base64,<%- image %>"/>
    </div>
  </div>
`);

export default BalsamiqViewer;
