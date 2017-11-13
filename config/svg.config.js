/* eslint-disable no-commonjs */
const path = require('path');
const fs = require('fs');

const sourcePath = path.join('node_modules', 'gitlab-svgs', 'dist');
const sourcePathIllustrations = path.join('node_modules', 'gitlab-svgs', 'dist', 'illustrations');
const destPath = path.normalize(path.join('app', 'assets', 'images'));

// Actual Task copying the 2 files + all illustrations
copyFileSync(path.join(sourcePath, 'icons.svg'), destPath);
copyFileSync(path.join(sourcePath, 'icons.json'), destPath);
copyFolderRecursiveSync(sourcePathIllustrations, destPath);

// Helper Functions
function copyFileSync(source, target) {
  var targetFile = target;
  //if target is a directory a new file with the same name will be created
  if (fs.existsSync(target)) {
    if (fs.lstatSync(target).isDirectory()) {
      targetFile = path.join(target, path.basename(source));
    }
  }
  console.log(`Copy SVG File : ${targetFile}`);
  fs.writeFileSync(targetFile, fs.readFileSync(source));
}

function copyFolderRecursiveSync(source, target) {
  var files = [];

  //check if folder needs to be created or integrated
  var targetFolder = path.join(target, path.basename(source));
  if (!fs.existsSync(targetFolder)) {
    fs.mkdirSync(targetFolder);
  }

  //copy
  if (fs.lstatSync(source).isDirectory()) {
    files = fs.readdirSync(source);
    files.forEach(function (file) {
      var curSource = path.join(source, file);
      if (fs.lstatSync(curSource).isDirectory()) {
        copyFolderRecursiveSync(curSource, targetFolder);
      } else {
        copyFileSync(curSource, targetFolder);
      }
    });
  }
}
