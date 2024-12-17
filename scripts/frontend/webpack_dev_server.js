const nodemon = require('nodemon');

const DEV_SERVER_HOST = process.env.DEV_SERVER_HOST || 'localhost';
const DEV_SERVER_PORT = process.env.DEV_SERVER_PORT || '3808';
const STATIC_MODE = process.env.DEV_SERVER_STATIC && process.env.DEV_SERVER_STATIC !== 'false';
const DLL_MODE = process.env.WEBPACK_VENDOR_DLL && process.env.WEBPACK_VENDOR_DLL !== 'false';

const baseConfig = {
  ignoreRoot: ['.git', 'node_modules/*/'],
  noUpdateNotifier: true,
  signal: 'SIGTERM',
  delay: 1000,
};

// run webpack in compile-once mode and watch for changes
if (STATIC_MODE) {
  nodemon({
    exec: `rm -rf public/assets/webpack ; yarn run webpack && exec ruby -run -e httpd public/ -p ${DEV_SERVER_PORT}`,
    watch: [
      'config/webpack.config.js',
      'app/assets/javascripts',
      'ee/app/assets/javascripts',
      // ensure we refresh when running yarn install
      'node_modules/.yarn-integrity',
    ],
    ext: 'js,json,vue',
    ...baseConfig,
  });
}

// run webpack through webpack-dev-server, optionally compiling a DLL to reduce memory
else {
  const watch = [
    'config/webpack.config.js',
    // ensure we refresh when running yarn install
    'node_modules/.yarn-integrity',
  ];

  // if utilizing the vendor DLL, we need to restart the process when dependency changes occur
  if (DLL_MODE) {
    watch.push('config/webpack.vendor.config.js', 'package.json', 'yarn.lock');
  }
  nodemon({
    exec: 'webpack-dev-server --config config/webpack.config.js',
    watch,
    ...baseConfig,
  });
}

let plugin = false;

// print useful messages for nodemon events
nodemon
  .on('start', () => {
    console.log(`Starting webpack webserver on http://${DEV_SERVER_HOST}:${DEV_SERVER_PORT}`);
    if (STATIC_MODE) {
      console.log('You are starting webpack in compile-once mode');
      console.log('The JavaScript assets are recompiled only if they change');
      console.log('If you change them often, you might want to unset DEV_SERVER_STATIC');
    }
    /* eslint-disable promise/catch-or-return */
    import('./lib/compile_css.mjs').then(({ simplePluginForNodemon }) => {
      plugin = simplePluginForNodemon({ shouldWatch: !STATIC_MODE });
      return plugin?.start();
    });
    import('./tailwindcss.mjs').then(({ webpackTailwindCompilerPlugin }) => {
      plugin = webpackTailwindCompilerPlugin({ shouldWatch: !STATIC_MODE });
      return plugin?.start();
    });
    /* eslint-enable promise/catch-or-return */
  })
  .on('quit', () => {
    console.log('Shutting down CSS compilation process');
    plugin?.stop();
    console.log('Shutting down webpack process');
    process.exit();
  })
  .on('restart', (files) => {
    console.log('Restarting webpack process due to: ', files);
    plugin?.start();
  });
