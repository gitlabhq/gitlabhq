const nodemon = require('nodemon');

const DEV_SERVER_HOST = process.env.DEV_SERVER_HOST || 'localhost';
const DEV_SERVER_PORT = process.env.DEV_SERVER_PORT || '3808';
const STATIC_MODE = process.env.DEV_SERVER_STATIC && process.env.DEV_SERVER_STATIC !== 'false';
const DLL_MODE = process.env.WEBPACK_VENDOR_DLL && process.env.WEBPACK_VENDOR_DLL !== 'false';
const USE_RSPACK = process.env.ENABLE_RSPACK === 'true';

const CONFIG_PATH = USE_RSPACK ? 'config/rspack.config.mjs' : 'config/webpack.config.js';
const BUILD_CMD = USE_RSPACK ? 'yarn run rspack-prod' : 'yarn run webpack';
const SERVE_CMD = USE_RSPACK
  ? // @rspack/cli doesn't set WEBPACK_SERVE (webpack-dev-server does); the config
    // keys HMR, bail, and lazy compilation off it.
    `WEBPACK_SERVE=true rspack serve --config ${CONFIG_PATH}`
  : `webpack-dev-server --config ${CONFIG_PATH}`;

const baseConfig = {
  ignoreRoot: ['.git', 'node_modules/*/'],
  noUpdateNotifier: true,
  signal: 'SIGTERM',
  delay: 1000,
};

// run the bundler in compile-once mode and watch for changes
if (STATIC_MODE) {
  nodemon({
    exec: `rm -rf public/assets/webpack ; ${BUILD_CMD} && exec ruby -run -e httpd public/ -p ${DEV_SERVER_PORT}`,
    watch: [
      CONFIG_PATH,
      'app/assets/javascripts',
      'ee/app/assets/javascripts',
      // ensure we refresh when running yarn install
      'node_modules/.yarn-integrity',
    ],
    ext: 'js,json,vue',
    ...baseConfig,
  });
}

// run the bundler's dev server, optionally compiling a DLL to reduce memory
else {
  const watch = [
    CONFIG_PATH,
    // ensure we refresh when running yarn install
    'node_modules/.yarn-integrity',
  ];

  // if utilizing the vendor DLL, we need to restart the process when dependency changes occur
  if (DLL_MODE) {
    watch.push('config/webpack.vendor.config.js', 'package.json', 'yarn.lock');
  }
  nodemon({
    exec: SERVE_CMD,
    watch,
    ...baseConfig,
  });
}

class Plugins {
  #plugins = [];

  addAndStart(plugin) {
    if (!plugin) return;

    this.#plugins.push(plugin);
    plugin.start();
  }

  call(method) {
    return Promise.all(this.#plugins.map((plugin) => plugin[method]?.()));
  }
}

const plugins = new Plugins();

let pluginsStarted = false;

function startPlugins() {
  // nodemon re-fires start in this same process when the bundler respawns, on a config
  // edit or a yarn install. The CSS and Tailwind plugins are independent and keep watching
  // across that, so running this again would stack a second set over the same files.
  if (pluginsStarted) return;

  pluginsStarted = true;

  /* eslint-disable promise/catch-or-return */
  import('./lib/compile_css.mjs').then(({ simplePluginForNodemon }) => {
    plugins.addAndStart(simplePluginForNodemon({ shouldWatch: !STATIC_MODE }));
  });
  import('./tailwindcss.cjs').then((mod) => {
    const { webpackTailwindCompilerPlugin } = mod.default;
    plugins.addAndStart(webpackTailwindCompilerPlugin({ shouldWatch: !STATIC_MODE }));
  });
  /* eslint-enable promise/catch-or-return */
}

nodemon
  .on('start', () => {
    console.log(`Starting webpack webserver on http://${DEV_SERVER_HOST}:${DEV_SERVER_PORT}`);
    if (STATIC_MODE) {
      console.log('You are starting webpack in compile-once mode');
      console.log('The JavaScript assets are recompiled only if they change');
      console.log('If you change them often, you might want to unset DEV_SERVER_STATIC');
    }
    startPlugins();
  })
  .on('crash', () => {
    // nodemon would sit here waiting for a file change that never comes, leaving
    // the process alive with nothing serving the dev server port. Exit instead,
    // so a supervisor restarts us and reports the service as down meanwhile.
    console.error(
      `The bundler crashed, so nothing is serving http://${DEV_SERVER_HOST}:${DEV_SERVER_PORT}. ` +
        'Exiting to let the process be restarted.',
    );

    plugins.call('stop');
    process.exit(1);
  })
  .on('quit', () => {
    console.log('Shutting down CSS compilation process');
    plugins.call('stop');
    console.log('Shutting down webpack process');
    process.exit();
  })
  .on('restart', (files) => {
    console.log('Restarting webpack process due to: ', files);
    plugins.call('start');
  });
