/* eslint-disable import/extensions */
import { exec as execCB } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import util from 'node:util';
import { createProcessor } from 'tailwindcss/lib/cli/build/plugin.js';

const exec = util.promisify(execCB);

// Note, in node > 21.2 we could replace the below with import.meta.dirname
const ROOT_PATH = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../');

const cssInJsPath = path.join(ROOT_PATH, 'config/helpers/tailwind/css_in_js.js');

export async function build({ shouldWatch = false, content = false } = {}) {
  const processorOptions = {
    '--watch': shouldWatch,
    '--output': path.join(ROOT_PATH, 'app/assets/builds', 'tailwind.css'),
    '--input': path.join(ROOT_PATH, 'app/assets/stylesheets', 'tailwind.css'),
  };

  const config = path.join(ROOT_PATH, 'config/tailwind.config.js');

  if (content) {
    console.log(`Setting content to ${content}`);
    processorOptions['--content'] = content;
  }

  const processor = await createProcessor(processorOptions, config);

  if (shouldWatch) {
    return processor.watch();
  }
  if (!process.env.REDIRECT_TO_STDOUT) {
    return processor.build();
  }
  // tailwind directly prints to stderr,
  // which we want to prevent in our static-analysis script
  const origError = console.error;
  console.error = console.log;
  await processor.build();
  console.error = origError;
  return null;
}

function wasScriptCalledDirectly() {
  return process.argv[1] === fileURLToPath(import.meta.url);
}

async function ensureCSSinJS() {
  console.log(`Ensuring ${cssInJsPath} exists`);
  const cmd = 'yarn run tailwindcss:build';

  const { stdout, error } = await exec(cmd, {
    env: { ...process.env, REDIRECT_TO_STDOUT: 'true' },
  });
  if (error) {
    throw error;
  }

  console.log(`'${cmd}' printed:`);
  console.log(`${stdout}`);
}

export function viteTailwindCompilerPlugin({ shouldWatch = true }) {
  return {
    name: 'gitlab-tailwind-compiler',
    async configureServer() {
      return build({ shouldWatch });
    },
  };
}

export function webpackTailwindCompilerPlugin({ shouldWatch = true }) {
  return {
    async start() {
      await ensureCSSinJS();
      return build({ shouldWatch });
    },
  };
}

if (wasScriptCalledDirectly()) {
  build();
}
