#!/usr/bin/env node

if (process.env.RAILS_ENV !== 'production') {
  console.log(
    `RAILS_ENV is not set to 'production': ${process.env.RAILS_ENV} - Not executing check`,
  );
  process.exit(0);
}

const fs = require('fs');
const path = require('path');
const glob = require('glob');
const pjs = require('postcss');

const paths = glob.sync('public/assets/page_bundles/_mixins_and_variables_and_functions*.css', {
  cwd: path.join(__dirname, '..', '..'),
});

if (!paths[0]) {
  console.log('Could not find mixins test file');
  process.exit(1);
}

console.log(`Checking ${paths[0]} for side effects`);

const file = fs.readFileSync(paths[0], 'utf-8');

const parsed = pjs.parse(file);

if (parsed.nodes.every((node) => ['comment', 'atrule'].includes(node.type))) {
  console.log('The file does not introduce any side effects, we are all good.');
  process.exit(0);
}

console.log(`At least one unwanted style was introduced.`);
process.exit(1);
