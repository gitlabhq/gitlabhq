/* eslint-disable no-underscore-dangle */
const { loadVue3Migrations, rolloutEntries } = require('../helpers/vue3_migration_loader');

const PLUGIN_NAME = 'Vue3MigrationManifestPlugin';

/**
 * Creates a webpack4 compatible "RawSource"
 *
 * Inspired from https://sourcegraph.com/github.com/FormidableLabs/webpack-stats-plugin@e050ff8c362d5ddd45c66ade724d4a397ace3e5c/-/blob/lib/stats-writer-plugin.js?L144
 */
const createWebpackRawSource = (source) => {
  const buff = Buffer.from(source, 'utf-8');

  return {
    source() {
      return buff;
    },
    size() {
      return buff.length;
    },
  };
};

/**
 * Webpack plugin that emits the Vue 3 migration runtime manifest.
 *
 * Packaged builds (Omnibus) strip `app/assets` from the Rails app, so the
 * co-located `vue3_migration.yml` files are not available at runtime in
 * production. This plugin compiles them into a single JSON manifest that
 * ships with the webpack output (`public/assets/webpack/`), which every
 * distribution preserves — Rails already reads `manifest.json` from there.
 * `Gitlab::Vue3Migration` loads the file in production and raises when it
 * is missing.
 *
 * Only `rollout` entries are included: Rails needs the feature flag name
 * to switch between the `<entry>` and `<entry>.vue3` bundles per request.
 * `migrated` pages build Vue 3 under the original entry name and need no
 * runtime metadata. The file is emitted even when empty (`{}`) — its
 * presence is the contract the Ruby side verifies.
 */
class Vue3MigrationManifestPlugin {
  constructor({ filename }) {
    this._filename = filename;
  }

  apply(compiler) {
    compiler.hooks.emit.tap(PLUGIN_NAME, (compilation) => {
      const contents = `${JSON.stringify(rolloutEntries(loadVue3Migrations()), null, 2)}\n`;
      const source = createWebpackRawSource(contents);

      const asset = compilation.getAsset(this._filename);
      if (asset) {
        compilation.updateAsset(this._filename, source);
      } else {
        compilation.emitAsset(this._filename, source);
      }
    });
  }
}

module.exports = Vue3MigrationManifestPlugin;
