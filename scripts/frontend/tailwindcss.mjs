import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createProcessor } from 'tailwindcss/lib/cli/build/plugin.js';

// Note, in node > 21.2 we could replace the below with import.meta.dirname
const ROOT_PATH = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../');

async function build({ shouldWatch = false } = {}) {
  const processor = await createProcessor(
    {
      '--watch': shouldWatch,
      '--output': path.join(ROOT_PATH, 'app/assets/builds/tailwind.css'),
      '--input': path.join(ROOT_PATH, 'app/assets/stylesheets/tailwind.css'),
    },
    path.join(ROOT_PATH, 'config/tailwind.config.js'),
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
