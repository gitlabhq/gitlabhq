import sqljs from 'sql.js';
import { template as _template } from 'underscore';

const PREVIEW_TEMPLATE = _template(`
  <div class="card">
    <div class="card-header"><%- name %></div>
    <div class="card-body">
      <img class="img-thumbnail" src="data:image/png;base64,<%- image %>"/>
    </div>
  </div>
`);

class BalsamiqViewer {
  constructor(viewer) {
    this.viewer = viewer;
  }

  loadFile(endpoint) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();

      xhr.open('GET', endpoint, true);
      xhr.responseType = 'arraybuffer';
      xhr.onload = loadEvent => this.fileLoaded(loadEvent, resolve, reject);
      xhr.onerror = reject;

      xhr.send();
    });
  }

  fileLoaded(loadEvent, resolve, reject) {
    if (loadEvent.target.status !== 200) return reject();

    this.renderFile(loadEvent);

    return resolve();
  }

  renderFile(loadEvent) {
    const container = document.createElement('ul');

    this.initDatabase(loadEvent.target.response);

    const previews = this.getPreviews();
    previews.forEach((preview) => {
      const renderedPreview = this.renderPreview(preview);

      container.appendChild(renderedPreview);
    });

    container.classList.add('list-inline');
    container.classList.add('previews');

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

  getResource(resourceID) {
    const resources = this.database.exec(`SELECT * FROM resources WHERE id = '${resourceID}'`);

    return resources[0];
  }

  renderPreview(preview) {
    const previewElement = document.createElement('li');

    previewElement.classList.add('preview');
    previewElement.innerHTML = this.renderTemplate(preview);

    return previewElement;
  }

  renderTemplate(preview) {
    const resource = this.getResource(preview.resourceID);
    const name = BalsamiqViewer.parseTitle(resource);
    const image = preview.image;

    const template = PREVIEW_TEMPLATE({
      name,
      image,
    });

    return template;
  }

  static parsePreview(preview) {
    return JSON.parse(preview[1]);
  }

  /*
   * resource = {
   *   columns: ['ID', 'BRANCHID', 'ATTRIBUTES', 'DATA'],
   *   values: [['id', 'branchId', 'attributes', 'data']],
   * }
   *
   * 'attributes' being a JSON string containing the `name` property.
   */
  static parseTitle(resource) {
    return JSON.parse(resource.values[0][2]).name;
  }
}

export default BalsamiqViewer;
