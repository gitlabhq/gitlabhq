const path = require('node:path');

const createProcessorModulePath = 'tailwindcss/lib/cli/build/plugin.js';

/**
 * Create a unique/isolated Tailwind processor.
 *
 * The `createProcessor` function from Tailwind [has module-local state][1].
 * This means if you call it twice, with different `cliConfigPath` arguments,
 * the second call produces a processor which uses the same configuration as
 * the first call.
 *
 * See where it [short-circuits][2] if there's an existing context.
 *
 * The workaround is to delete Node's [module cache][3] of the file that has
 * the local state before `require`ing it. This is quite brittle: if Tailwind
 * gets updated and the module the local state lives in changes, this work
 * around will no longer work. This shouldn't be a problem, though, because:
 *
 * - We're on Tailwind v3, and given v4 is available, it's unlikely to receive
 *   any updates other than bug fixes.
 * - This hack will only exist as long as the `paneled_view`
 *   feature flag exists. That is, it is temporary, to help with the
 *   [migration to container queries][4].
 *
 * [1]: https://github.com/tailwindlabs/tailwindcss/blob/v3.4.1/src/cli/build/plugin.js#L111
 * [2]: https://github.com/tailwindlabs/tailwindcss/blob/v3.4.1/src/cli/build/plugin.js#L218-L222
 * [3]: https://nodejs.org/api/modules.html#requirecache
 * [4]: https://gitlab.com/groups/gitlab-org/-/epics/18787
 */
function createUniqueProcessor(...args) {
  delete require.cache[require.resolve(createProcessorModulePath)];
  // eslint-disable-next-line import/no-dynamic-require, global-require
  return require(createProcessorModulePath).createProcessor(...args);
}

const ROOT_PATH = path.resolve(__dirname, '../../');

async function build({
  shouldWatch = false,
  content = false,
  buildCQs = false,
  needsUniqueProcessor = true,
} = {}) {
  const configFile = buildCQs ? 'tailwind_cqs.config.js' : 'tailwind.config.js';
  const outputBundle = buildCQs ? 'tailwind_cqs.css' : 'tailwind.css';

  const processorOptions = {
    '--watch': shouldWatch,
    '--output': path.join(ROOT_PATH, 'app/assets/builds', outputBundle),
    '--input': path.join(ROOT_PATH, 'app/assets/stylesheets', 'tailwind.css'),
  };

  const config = path.join(ROOT_PATH, 'config', configFile);

  if (content) {
    console.log(`Setting content to ${content}`);
    processorOptions['--content'] = content;
  }

  let processor;
  if (needsUniqueProcessor) {
    processor = await createUniqueProcessor(processorOptions, config);
  } else {
    // eslint-disable-next-line import/no-dynamic-require, global-require
    processor = await require(createProcessorModulePath).createProcessor(processorOptions, config);
  }

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
  return require.main === module;
}

function viteTailwindCompilerPlugin({ shouldWatch = true, buildCQs = false }) {
  return {
    name: 'gitlab-tailwind-compiler',
    async configureServer() {
      return build({ shouldWatch, buildCQs });
    },
  };
}

function webpackTailwindCompilerPlugin({ shouldWatch = true, buildCQs = false }) {
  return {
    async start() {
      return build({ shouldWatch, buildCQs });
    },
  };
}

if (wasScriptCalledDirectly()) {
  const buildCQs = Boolean(process.env.USE_TAILWIND_CONTAINER_QUERIES);
  build({ buildCQs, needsUniqueProcessor: false })
    // eslint-disable-next-line promise/always-return
    .then(() => {
      console.log('Tailwind utils built successfully');
    })
    .catch((e) => {
      console.warn('Building Tailwind utils produced an error');
      console.error(e);
      process.exitCode = 1;
    });
}

Object.assign(module.exports, {
  build,
  viteTailwindCompilerPlugin,
  webpackTailwindCompilerPlugin,
});
