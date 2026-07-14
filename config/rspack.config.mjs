import './helpers/patched_crypto.js';

import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { RsdoctorRspackPlugin } from '@rsdoctor/rspack-plugin';
// eslint-disable-next-line import/no-unresolved -- resolver doesn't read @rspack/core's exports field
import rspack from '@rspack/core';
import CompressionPlugin from 'compression-webpack-plugin';
import gqlTag from 'graphql-tag';

import { buildOutput } from './helpers/output.js';
import { aliases } from './helpers/aliases.js';
import { supportedBrowsersHash } from './helpers/supported_browsers.js';
import { VUE_VERSION, VUE_COMPILER_VERSION, logVueVersion } from './helpers/vue_version.js';
import { cacheGroups } from './rspack/cache_groups.js';
import { define } from './rspack/define.js';
import { entries } from './rspack/entries.js';
import GraphqlKnownOperationsPlugin from './plugins/graphql_known_operations_plugin.js';
import { buildLoaderRules } from './rspack/loader_rules.js';
import {
  DEVTOOL,
  HASHED_CHUNKS,
  COMPRESSION,
  MINIFY,
  RSDOCTOR,
  RSDOCTOR_LEAN,
} from './rspack/settings.js';
import {
  IS_EE,
  IS_JH,
  ROOT_PATH,
  WEBPACK_PUBLIC_PATH,
  copyFilesPatterns,
  IS_PRODUCTION,
  IS_DEV_SERVER,
  DEV_SERVER_HOST,
  DEV_SERVER_PUBLIC_ADDR,
  DEV_SERVER_PORT,
  DEV_SERVER_ALLOWED_HOSTS,
  DEV_SERVER_LIVERELOAD,
} from './webpack.constants.js';

const configPath = fileURLToPath(import.meta.url);
const require = createRequire(import.meta.url);

logVueVersion('[Rspack]');

gqlTag.disableFragmentWarnings();

const replaceWithEmptyComponent = (pattern) =>
  new rspack.NormalModuleReplacementPlugin(pattern, (resource) => {
    // eslint-disable-next-line no-param-reassign
    resource.request = path.join(
      ROOT_PATH,
      'app/assets/javascripts/vue_shared/components/empty_component.js',
    );
  });

const plugins = [
  new rspack.CopyRspackPlugin({ patterns: copyFilesPatterns }),
  new GraphqlKnownOperationsPlugin({ filename: 'graphql_known_operations.yml' }),
  new rspack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    process: [require.resolve('process/browser')],
  }),
  !IS_EE && replaceWithEmptyComponent(/^ee_component\/(.*)\.vue/),
  !IS_JH && replaceWithEmptyComponent(/^jh_component\/(.*)\.vue/),
  !IS_EE && !IS_JH && replaceWithEmptyComponent(/^jh_else_ee\/(.*)\.vue/),
  new rspack.ContextReplacementPlugin(/^\.$/, (context) => {
    if (!/\/node_modules\/pdfjs-dist/.test(context.context)) return;
    for (const d of context.dependencies || []) {
      if (d.critical) d.critical = false;
    }
  }),
  new rspack.DefinePlugin(define),
  new rspack.IgnorePlugin({ resourceRegExp: /moment/, contextRegExp: /pikaday/ }),
  IS_PRODUCTION && COMPRESSION !== false && new CompressionPlugin(),
  RSDOCTOR &&
    new RsdoctorRspackPlugin(
      RSDOCTOR_LEAN
        ? {
            output: { mode: 'brief' },
            features: ['bundle'],
            supports: { generateTileGraph: false },
          }
        : {},
    ),
].filter(Boolean);

// Static builds rename entry chunks to Webpack's `[name].chunk.js` (runtimeChunk:'single'
// routes the runtime through output.filename, entry code through chunkFilename). The dev
// server keeps the defaults — renaming entry chunks there breaks persistent-cache/HMR.
const output = (() => {
  const base = buildOutput({ hashChunks: HASHED_CHUNKS });
  if (IS_DEV_SERVER) return base;
  return {
    ...base,
    filename: (pathData) =>
      pathData.chunk?.name === 'runtime' ? base.filename : base.chunkFilename,
  };
})();

// eslint-disable-next-line import/no-default-export -- Rspack's config loader reads the default export
export default {
  bail: !IS_DEV_SERVER,
  mode: IS_PRODUCTION ? 'production' : 'development',
  context: path.join(ROOT_PATH, 'app/assets/javascripts'),
  target: 'web',
  devtool: DEVTOOL,
  entry: entries,
  output,
  resolve: {
    extensions: ['.mjs', '.js'],
    alias: {
      ...aliases,
      // Rspack honors Vue's package "exports" field, so a bare `vue` import can resolve
      // to two different runtime builds (two Vue instances). Pin to one build.
      ...(VUE_VERSION === '3' ? {} : { vue$: 'vue/dist/vue.runtime.esm.js' }),
      // Same hazard for @vue/compat: pin every import to the single runtime build the
      // infection alias targets, else getCurrentInstance() returns null in the stray copy.
      '@vue/compat$': path.join(
        ROOT_PATH,
        'node_modules/@vue/compat/dist/vue.runtime.esm-bundler.js',
      ),
    },
    fallback: { fs: false, path: false, 'graphql-ws': false },
  },
  module: {
    rules: buildLoaderRules(),
  },
  optimization: {
    runtimeChunk: 'single',
    // Use the real NODE_ENV (not `mode`) so the app's env-gated behavior matches Webpack.
    nodeEnv: process.env.NODE_ENV || 'development',
    minimize: IS_PRODUCTION && MINIFY !== false,
    splitChunks: {
      maxInitialRequests: 20,
      maxAsyncRequests: 20,
      minSize: 150000,
      automaticNameDelimiter: '-',
      cacheGroups,
    },
  },
  experiments: {
    css: false,
  },
  node: {
    __dirname: 'mock',
    __filename: 'mock',
  },
  lazyCompilation: {
    imports: true,
    entries: false,
    prefix: `${WEBPACK_PUBLIC_PATH}_rspack/lazy/trigger`,
  },
  devServer: {
    devMiddleware: {
      stats: 'errors-only',
    },
    host: DEV_SERVER_HOST || 'localhost',
    port: DEV_SERVER_PORT || 3808,
    webSocketServer: DEV_SERVER_LIVERELOAD ? 'ws' : false,
    hot: DEV_SERVER_LIVERELOAD,
    liveReload: DEV_SERVER_LIVERELOAD,
    allowedHosts: DEV_SERVER_ALLOWED_HOSTS || 'all',
    client: {
      ...(DEV_SERVER_PUBLIC_ADDR ? { webSocketURL: DEV_SERVER_PUBLIC_ADDR } : {}),
      overlay: {
        runtimeErrors: (error) => {
          return !(
            error instanceof DOMException && error.message === 'The user aborted a request.'
          );
        },
      },
    },
  },
  plugins,
  cache: IS_PRODUCTION
    ? false
    : {
        type: 'persistent',
        version: [
          supportedBrowsersHash,
          `vue${VUE_VERSION}`,
          `compiler${VUE_COMPILER_VERSION}`,
        ].join('-'),
        buildDependencies: [configPath],
        storage: {
          type: 'filesystem',
          directory: path.join(ROOT_PATH, 'tmp/cache/rspack'),
        },
      },
  stats: {
    children: false,
    chunks: false,
    modules: false,
  },
  infrastructureLogging: {
    level: 'warn',
  },
};
