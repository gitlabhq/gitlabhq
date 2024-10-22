const { readFile } = require('node:fs/promises');
const { join } = require('node:path');

function parse(quarantineFileContent) {
  return quarantineFileContent
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'));
}

async function getLocalQuarantinedFiles() {
  const content = await readFile(join(__dirname, 'quarantined_vue3_specs.txt'), {
    encoding: 'UTF-8',
  });

  return parse(content);
}

Object.assign(module.exports, {
  parse,
  getLocalQuarantinedFiles,
});
