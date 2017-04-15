import DXFParser from 'dxf-parser';
import DXF from './dxf';

export default class DXFRenderer {
  constructor(container) {
    this.el = container;
    this.endpoint = this.el.dataset.endpoint;
    this.loadFile();
  }

  loadFile() {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', this.endpoint, true);
    xhr.responseType = 'string';
    xhr.onload = this.parseDxf.bind(this);
    // xhr.onerror = DXFParser.onError;
    xhr.send();
  }

  parseDxf(e) {
    var parser = new DXFParser();
    try {
        var dxf = parser.parseSync(e.target.response);
        console.log(dxf)
    }catch(err) {
        return console.error(err.stack);
    }
  }
}