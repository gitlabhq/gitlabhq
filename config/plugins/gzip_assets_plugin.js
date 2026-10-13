const os = require('node:os');
const zlib = require('node:zlib');
const { promisify } = require('node:util');

const gzip = promisify(zlib.gzip);

const PLUGIN_NAME = 'GzipAssetsPlugin';

class GzipAssetsPlugin {
  constructor({
    exclude = /\.map$/,
    level = 9,
    minRatio = 0.8,
    concurrency = os.availableParallelism(),
  } = {}) {
    this.exclude = exclude;
    this.level = level;
    this.minRatio = minRatio;
    this.concurrency = concurrency;
  }

  apply(compiler) {
    const { Compilation, sources } = compiler.rspack;

    compiler.hooks.compilation.tap(PLUGIN_NAME, (compilation) => {
      compilation.hooks.processAssets.tapPromise(
        { name: PLUGIN_NAME, stage: Compilation.PROCESS_ASSETS_STAGE_OPTIMIZE_TRANSFER },
        () => this.compressAssets(compilation, sources.RawSource),
      );
    });
  }

  async compressAssets(compilation, RawSource) {
    const names = compilation
      .getAssets()
      .map(({ name }) => name)
      .filter((name) => !this.exclude.test(name));
    const queue = names.values();

    const worker = async () => {
      for (const name of queue) {
        const asset = compilation.getAsset(name);
        if (!asset || asset.info.compressed) continue;

        const input = asset.source.buffer();
        // eslint-disable-next-line no-await-in-loop -- each worker drains the shared queue sequentially
        const output = await gzip(input, { level: this.level });
        if (output.length / input.length > this.minRatio) continue;

        compilation.emitAsset(`${name}.gz`, new RawSource(output), { compressed: true });
      }
    };

    await Promise.all(Array.from({ length: Math.min(this.concurrency, names.length) }, worker));
  }
}

module.exports = GzipAssetsPlugin;
