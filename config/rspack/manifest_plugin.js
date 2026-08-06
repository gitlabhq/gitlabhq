const { StatsWriterPlugin } = require('webpack-stats-plugin');

function toStringMessages(list) {
  return (list || []).map((e) => {
    if (typeof e === 'string') return e;
    return (e && (e.message || e.formatted)) || String(e);
  });
}

function slimManifest() {
  return new StatsWriterPlugin({
    filename: 'manifest.rspack.json',
    transform(data, opts) {
      const stats = opts.compiler.getStats().toJson({
        assets: true,
        entrypoints: true,
        chunkGroups: true,
        chunkModules: false,
        source: false,
        chunks: false,
        modules: false,
        errors: true,
        warnings: true,
      });

      // Strip HMR hot-update files: if they reach Rails as page <script> tags they
      // run outside the HMR check flow, where rspackHotUpdate() throws before init
      // and forces a reload. The HMR runtime fetches them itself. (No-op in prod.)
      const isHotUpdate = (name) => typeof name === 'string' && name.includes('.hot-update.');

      const entrypoints = {};
      for (const [name, ep] of Object.entries(stats.entrypoints || {})) {
        entrypoints[name] = {
          assets: (ep.assets || [])
            .map((a) => (typeof a === 'string' ? a : a.name))
            .filter((a) => !isHotUpdate(a)),
        };
      }

      const assetsByChunkName = {};
      for (const [name, value] of Object.entries(stats.assetsByChunkName || {})) {
        if (Array.isArray(value)) {
          assetsByChunkName[name] = value.filter((a) => !isHotUpdate(a));
        } else if (!isHotUpdate(value)) {
          assetsByChunkName[name] = value;
        }
      }

      return JSON.stringify({
        errors: toStringMessages(stats.errors),
        warnings: toStringMessages(stats.warnings),
        assetsByChunkName,
        entrypoints,
      });
    },
  });
}

module.exports = { slimManifest };
