import Vue from 'vue';
import sqljs from 'sql.js';

export default class BalsamiqViewer {
  constructor(el) {
    this.el = el;
    this.loadSqlFile();
  }
  
  
  loadSqlFile() {
    var xhr = new XMLHttpRequest();
    var self = this;
    xhr.open('GET', this.el.dataset.endpoint, true);
    xhr.responseType = 'arraybuffer';

    xhr.onload = function(e) {
      var list = document.createElement('ul');
      var uInt8Array = new Uint8Array(this.response);
      var db = new SQL.Database(uInt8Array);
      var contents = db.exec("SELECT * FROM thumbnails");
      var previews = contents[0].values.map((i)=>{return JSON.parse(i[1])});
      previews.forEach((prev) => {
        var li = document.createElement('li');
        var title = db.exec(`select * from resources where id = '${prev.resourceID}'`)
        var template = 
        `<div class="panel panel-default">
            <div class="panel-heading">${JSON.parse(title[0].values[0][2]).name}</div>
            <div class="panel-body">
              <img class="img-thumbnail" src="data:image/png;base64,${prev.image}"/>
            </div>
          </div>`;
        li.innerHTML = template;
        list.appendChild(li);
      });
      list.classList += 'list-inline';
      self.el.appendChild(list);
    };
    xhr.send();
  }
}