import JSZip from 'jszip';
import JSZipUtils from 'jszip-utils';
import Vue from 'vue';

export default class ZipRenderer {
  constructor(container) {
    this.el = container;
    this.load();
    this.files = {};
  }

  load() {
    return this.getZipFile()
      .then(data => {
        return JSZip.loadAsync(data,{
          createFolders: false
        })
      })
      .then(asyncResult => {
        this.files = this.createUsefulZipObjectStructure(asyncResult);
        this.addVue(this.files);
      })
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


  createUsefulZipObjectStructure(files) {
    files = Object.keys(files.files);
    var result = files.reduce(function(acc, record) {
      var fields = record.match(/[^\/]+\/?/g) || [];
      var currentDir = acc;
         
      fields.forEach(function (field, idx) {

        // If field is a directory...
        if (/\/$/.test(field)) {
          
          // If first one and not an existing directory, add it
          if (idx == 0) {
            if (!(field in currentDir)) {
              currentDir[field] = [];
            }
            
            // Move into subdirectory
            currentDir = currentDir[field];
            
          // If not first, see if it's a subdirectory of currentDir
          } else {
            // Look for field as a subdirectory of currentDir
            var subDir = currentDir.filter(function(element){
              return typeof element == 'object' && element[field];
            })[0];
            
            // If didn't find subDir, add it and set as currentDir
            if (!subDir) {
              var t = Object.create(null);
              t[field] = [];
              currentDir.push(t);
              currentDir = t[field];
              
            // If found, set as currentDir
            } else {
              currentDir = subDir[field];
            }
          }
          
        // Otherwise it's a file. Make sure currentDir is a directory and not the root
        } else {
          if (Array.isArray(currentDir)) {
            currentDir.push(field);
            
          // Otherwise, must be at root where files aren't allowed
          } else {
            throw new Error('Files not allowed in root: ' + field);
          }
        }
      });
      
      return acc;
      
    }, Object.create(null));
    return result;
  }

  addVue(files) {
    this.vue = new Vue({
      el: '#js-zip-viewer',
      data() {
        return {
          files: files
        }
      }
    });
  }

}