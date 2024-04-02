/* eslint-disable import/extensions */
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createProcessor } from 'tailwindcss/lib/cli/build/plugin.js';

// Note, in node > 21.2 we could replace the below with import.meta.dirname
const ROOT_PATH = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../');

async function build({ shouldWatch = false } = {}) {
  let config = path.join(ROOT_PATH, 'config/tailwind.config.js');
  let fileName = 'tailwind.css';
  if (process.env.TAILWIND_ALL_THE_WAY) {
    config = path.join(ROOT_PATH, 'config/tailwind.all_the_way.config.js');
    fileName = 'tailwind_all_the_way.css';
  }

  const processor = await createProcessor(
    {
      '--watch': shouldWatch,
      '--output': path.join(ROOT_PATH, 'app/assets/builds', fileName),
      '--input': path.join(ROOT_PATH, 'app/assets/stylesheets', fileName),
    },
    config,
  );

  if (shouldWatch) {
    processor.watch();
  } else {
    processor.build();
  }
}

function wasScriptCalledDirectly() {
  return process.argv[1] === fileURLToPath(import.meta.url);
}

export function viteTailwindCompilerPlugin({ shouldWatch = true }) {
  return {
    name: 'gitlab-tailwind-compiler',
    async configureServer() {
      build({ shouldWatch });
    },
  };
}

export function webpackTailwindCompilerPlugin({ shouldWatch = true }) {
  return {
    async start() {
      build({ shouldWatch });
    },
  };
}

if (wasScriptCalledDirectly()) {
  build();
}
