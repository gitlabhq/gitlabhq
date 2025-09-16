#!/usr/bin/env node

import fs from 'node:fs';
import { program } from 'commander';
import { migrateCSSUtils, migrateMediaQueries } from './lib/container_queries_migration.mjs';

program.argument('<files...>').parse();

function getFileContents(file) {
  return fs.readFileSync(file, 'utf-8');
}

function writeFileContents(file, contents) {
  return fs.writeFileSync(file, contents, 'utf-8');
}

function processFiles(files) {
  files.forEach((file) => {
    let contents = getFileContents(file);
    if (
      file.endsWith('.vue') ||
      file.endsWith('.js') ||
      file.endsWith('.haml') ||
      file.endsWith('.rb')
    ) {
      contents = migrateCSSUtils(contents);
    } else if (file.endsWith('.scss')) {
      contents = migrateMediaQueries(contents);
    } else {
      console.log(`File ${file} is not supported.`);
    }
    writeFileContents(file, contents);
  });
}

function main() {
  processFiles(program.args);
}

main();
