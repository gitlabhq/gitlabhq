import Vue from 'vue';
import sqljs from 'sql.js';

export default class BalsamiqViewer {
  constructor(el) {
    this.el = el;
    this.loadSqlFile();
  }
  
  

  loadSqlFile() {
    var xhr = new XMLHttpRequest();
    console.log(this.el)
    xhr.open('GET', this.el.dataset.endpoint, true);
    xhr.responseType = 'arraybuffer';

    xhr.onload = function(e) {
      var uInt8Array = new Uint8Array(this.response);
      var db = new SQL.Database(uInt8Array);
      var contents = db.exec("SELECT * FROM thumbnails");
      console.log(contents)
      // contents is now [{columns:['col1','col2',...], values:[[first row], [second row], ...]}]
    };
    xhr.send();
  }
}