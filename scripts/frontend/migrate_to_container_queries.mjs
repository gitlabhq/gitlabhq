#!/usr/bin/env node

import fs from 'node:fs';
import { styleText } from 'node:util';
import { program } from 'commander';
import {
  isFileExcluded,
  migrateCSSUtils,
  migrateMediaQueries,
} from './lib/container_queries_migration.mjs';

program.argument('<files...>').parse();

function getFileContents(file) {
  return fs.readFileSync(file, 'utf-8');
}

function writeFileContents(file, contents) {
  return fs.writeFileSync(file, contents, 'utf-8');
}

function isMarkupExtension(file) {
  return (
    file.endsWith('.vue') ||
    file.endsWith('.js') ||
    file.endsWith('.haml') ||
    file.endsWith('.rb') ||
    file.endsWith('.erb')
  );
}

function isScssExtension(file) {
  return file.endsWith('.scss');
}

function processFiles(files) {
  const counts = {
    ignored: 0,
    migrated: 0,
    unchanged: 0,
    not_supported: 0,
    total: 0,
  };

  files.forEach((file) => {
    counts.total += 1;
    if (isFileExcluded(file)) {
      console.log(`\`${file}\`: ignored by an exclusion pattern, skipping.`);
      counts.ignored += 1;
      return;
    }
    if (!isMarkupExtension(file) && !isScssExtension(file)) {
      console.log(`\`${file}\`: not supported.`);
      counts.not_supported += 1;
      return;
    }

    const contents = getFileContents(file);
    let newContents;
    if (isMarkupExtension(file)) {
      newContents = migrateCSSUtils(file, contents);
    }
    if (isScssExtension(file)) {
      newContents = migrateMediaQueries(file, contents);
    }

    if (contents !== newContents) {
      writeFileContents(file, newContents);
      counts.migrated += 1;
    } else {
      counts.unchanged += 1;
    }
  });

  return counts;
}

function main() {
  const counts = processFiles(program.args);

  console.log(`\nProcessed ${counts.total} files`);
  console.log(styleText('green', `  ${counts.migrated} files migrated`));
  console.log(styleText('gray', `  ${counts.unchanged} files unchanged`));
  console.log(styleText('yellow', `  ${counts.ignored} files ignored`));
  console.log(styleText('red', `  ${counts.not_supported} not supported`));
}

main();
