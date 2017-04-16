import JSZip from 'jszip';
import JSZipUtils from 'jszip-utils';
import Vue from 'vue';

export default class ZipRenderer {
  constructor(container) {
    this.el = container;
    this.absolutePaths = [];
    this.load();
    this.files = [];
    this.tree = [];
    this.addVue();
  }

  load() {
    return this.getZipFile()
      .then(data => {
        return JSZip.loadAsync(data,{
          createFolders: false
        })
      })
      .then(asyncResult => {
        this.createUsefulZipObjectStructure(asyncResult);
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

  // Extract filename from a path
  getFilename(path) {
    return path.split("/").filter((i) => {
      return i && i.length; 
    }).reverse()
    [0];
  }

  // Get depth of a path
  getPathDepth(path) {
    return path.replace(/[^\/]+|\/$/g, '').length;
  }

  // Find sub paths
  findSubPaths(path) {
    var subPaths = [];
    var depth = this.getPathDepth(path);
    return this.absolutePaths.filter((i) => {
      var d = this.getPathDepth(i);
      return i != path && i.startsWith(path) && (d <= depth+1);
    });
  }

  // Build tree recursively
  buildTree(dirPath) {
    var tree = [];
    var key = this.getFilename(dirPath);
    var subPaths = this.findSubPaths(dirPath);
    subPaths.forEach((subPath) => {
      var subKey = this.getFilename(subPath);
      if(/\/$/.test(subPath)) {
        var o = {};
        o[subKey] = this.buildTree(subPath);
        tree.push(o);     
      }
      else {
        tree.push(subKey);
      } 
    });
    return tree;
  }

  createUsefulZipObjectStructure(files) {
    var tree;
    this.absolutePaths = [];
    files.forEach((path) => {
      this.absolutePaths.push("/" + path);
    });
    tree = this.buildTree("/");
  }

  addVue() {
    this.vue = new Vue({

    });
  }

}