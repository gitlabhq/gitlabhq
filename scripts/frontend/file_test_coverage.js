#!/usr/bin/env node

/**
 * Counts the number of frontend test files and compares them against the number of application files.
 *
 * Example output:
 *
 * Source files: 1551
 * Test files: 716
 * Coverage: 46.16%
 */

const fs = require('fs');
const path = require('path');

const sourceDirectories = ['app/assets/javascripts'];
const testDirectories = ['spec/javascripts', 'spec/frontend'];

if (fs.existsSync('ee')) {
  sourceDirectories.forEach((dir) => {
    sourceDirectories.push(`ee/${dir}`);
  });

  testDirectories.forEach((dir) => {
    testDirectories.push(`ee/${dir}`);
  });
}

let numSourceFiles = 0;
let numTestFiles = 0;

const isVerbose = process.argv.some((arg) => arg === '-v');

function forEachFileIn(dirPath, callback) {
  fs.readdir(dirPath, (err, files) => {
    if (err) {
      console.error(err);
    }

    if (!files) {
      return;
    }

    files.forEach((fileName) => {
      const absolutePath = path.join(dirPath, fileName);
      const stats = fs.statSync(absolutePath);
      if (stats.isFile()) {
        callback(absolutePath);
      } else if (stats.isDirectory()) {
        forEachFileIn(absolutePath, callback);
      }
    });
  });
}

const countSourceFiles = (currentPath) =>
  forEachFileIn(currentPath, (fileName) => {
    if (fileName.endsWith('.vue') || fileName.endsWith('.js')) {
      if (isVerbose) {
        console.log(`source file: ${fileName}`);
      }

      numSourceFiles += 1;
    }
  });

const countTestFiles = (currentPath) =>
  forEachFileIn(currentPath, (fileName) => {
    if (fileName.endsWith('_spec.js')) {
      if (isVerbose) {
        console.log(`test file: ${fileName}`);
      }

      numTestFiles += 1;
    }
  });

console.log(`Source directories: ${sourceDirectories.join(', ')}`);
console.log(`Test directories: ${testDirectories.join(', ')}`);

sourceDirectories.forEach(countSourceFiles);
testDirectories.forEach(countTestFiles);

process.on('exit', () => {
  console.log(`Source files: ${numSourceFiles}`);
  console.log(`Test files: ${numTestFiles}`);
  console.log(`Coverage: ${((100 * numTestFiles) / numSourceFiles).toFixed(2)}%`);
});
