#!/usr/bin/env node

// Lint mermaid code in markdown files.
// Usage: scripts/lint/check_mermaid.mjs [files ...]

import fs from 'node:fs';
import glob from 'glob';
import mermaid from 'mermaid';
import DOMPurify from 'dompurify';
import { JSDOM } from 'jsdom';

const jsdom = new JSDOM('...', {
  pretendToBeVisual: true,
});
global.document = jsdom;
global.window = jsdom.window;
global.Option = window.Option;

// Workaround to make DOMPurify not fail.
// See https://github.com/mermaid-js/mermaid/issues/5204
DOMPurify.addHook = () => {};
DOMPurify.sanitize = (x) => x;

const defaultGlob = 'doc/**/*.md';
const mermaidMatch = /```mermaid(.*?)```/gms;

const argv = process.argv.length > 2 ? process.argv.slice(2) : [defaultGlob];
const mdFiles = argv.flatMap((arg) => glob.sync(arg));

console.log(`Checking ${mdFiles.length} markdown files...`);

// Mimicking app/assets/javascripts/lib/mermaid.js
mermaid.initialize({
  // mermaid core options
  mermaid: {
    startOnLoad: false,
  },
  // mermaidAPI options
  theme: 'neutral',
  flowchart: {
    useMaxWidth: true,
    htmlLabels: true,
  },
  secure: ['secure', 'securityLevel', 'startOnLoad', 'maxTextSize', 'htmlLabels'],
  securityLevel: 'strict',
  dompurifyConfig: {
    ADD_TAGS: ['foreignObject'],
    HTML_INTEGRATION_POINTS: { foreignobject: true },
  },
});

let errors = 0;

await Promise.all(
  mdFiles.map((path) => {
    const data = fs.readFileSync(path, 'utf8');

    const matched = [...data.matchAll(mermaidMatch)];

    return Promise.all(
      matched.map((match) => {
        const matchIndex = match.index;
        const mermaidText = match[1];

        return mermaid.parse(mermaidText).catch((error) => {
          const lineNumber = data.slice(0, matchIndex).split('\n').length;

          console.log(`${path}:${lineNumber}: Mermaid syntax error\nError: ${error}\n`);
          errors += 1;
        });
      }),
    );
  }),
);

if (errors > 0) {
  console.log(`Total errors: ${errors}`);
  console.log(
    `To fix these errors, see https://docs.gitlab.com/ee/development/documentation/testing/#mermaid-chart-linting.`,
  );
  process.exit(1);
}
