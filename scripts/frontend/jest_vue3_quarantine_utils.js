const { readFile } = require('node:fs/promises');
const { join } = require('node:path');
const { setTimeout: setTimeoutPromise } = require('node:timers/promises');
const axios = require('axios');

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

// See https://gitlab.com/gitlab-org/frontend/playground/fast-jest-vue-3-quarantine for details
// about how to fast quarantine files.
async function getFastQuarantinedFiles(n = 0, maxRetries = 3) {
  const url =
    'https://gitlab-org.gitlab.io/frontend/playground/fast-jest-vue-3-quarantine/gitlab.txt';

  try {
    const { data } = await axios.get(url, { timeout: 10_000 });
    return parse(data);
  } catch (error) {
    console.error('\nFailed to fetch list of specs failing with @vue/compat: %s', error.message);

    if (n < maxRetries) {
      const waitMs = 5_000 * 2 ** n;
      console.error(`Waiting ${waitMs}ms to retry (${maxRetries - n} remaining)`);
      await setTimeoutPromise(waitMs);
      return getFastQuarantinedFiles(n + 1);
    }

    throw error;
  }
}

Object.assign(module.exports, {
  parse,
  getLocalQuarantinedFiles,
  getFastQuarantinedFiles,
});
