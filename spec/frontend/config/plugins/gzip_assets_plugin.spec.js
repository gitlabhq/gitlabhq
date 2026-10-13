import { randomBytes } from 'node:crypto';
import { gunzipSync } from 'node:zlib';
import GzipAssetsPlugin from '../../../../config/plugins/gzip_assets_plugin';

const OPTIMIZE_TRANSFER = 700;

class RawSource {
  constructor(buffer) {
    this.buffer = buffer;
  }
}

const createCompilation = (assets) => {
  const byName = new Map(
    Object.entries(assets).map(([name, { content, info = {} }]) => [
      name,
      { name, info, source: { buffer: () => Buffer.from(content) } },
    ]),
  );

  return {
    hooks: { processAssets: { tapPromise: jest.fn() } },
    getAssets: () => [...byName.values()],
    getAsset: (name) => byName.get(name),
    emitAsset: jest.fn(),
  };
};

const runPlugin = async (compilation, options) => {
  const compiler = {
    rspack: {
      Compilation: { PROCESS_ASSETS_STAGE_OPTIMIZE_TRANSFER: OPTIMIZE_TRANSFER },
      sources: { RawSource },
    },
    hooks: { compilation: { tap: jest.fn() } },
  };

  new GzipAssetsPlugin(options).apply(compiler);
  compiler.hooks.compilation.tap.mock.calls[0][1](compilation);

  const [tapOptions, callback] = compilation.hooks.processAssets.tapPromise.mock.calls[0];
  await callback();

  return tapOptions;
};

const emittedNames = (compilation) => compilation.emitAsset.mock.calls.map(([name]) => name);

describe('GzipAssetsPlugin', () => {
  const compressible = 'const a = 1;\n'.repeat(200);

  it('taps processAssets at the optimize-transfer stage', async () => {
    const tapOptions = await runPlugin(createCompilation({}));

    expect(tapOptions).toEqual({ name: 'GzipAssetsPlugin', stage: OPTIMIZE_TRANSFER });
  });

  it('emits a gzip sibling whose content decompresses to the original asset', async () => {
    const compilation = createCompilation({ 'main.js': { content: compressible } });

    await runPlugin(compilation);

    const [[name, source, info]] = compilation.emitAsset.mock.calls;
    expect(name).toBe('main.js.gz');
    expect(info).toEqual({ compressed: true });
    expect(gunzipSync(source.buffer).toString()).toBe(compressible);
  });

  it('skips source maps, already compressed assets and assets that do not compress well', async () => {
    const compilation = createCompilation({
      'main.js': { content: compressible },
      'main.js.map': { content: compressible },
      'vendor.js': { content: compressible, info: { compressed: true } },
      'noise.png': { content: randomBytes(4096) },
    });

    await runPlugin(compilation);

    expect(emittedNames(compilation)).toEqual(['main.js.gz']);
  });

  it('compresses every asset when there are more assets than workers', async () => {
    const assets = Object.fromEntries(
      Array.from({ length: 25 }, (_, i) => [`chunk-${i}.js`, { content: compressible }]),
    );
    const compilation = createCompilation(assets);

    await runPlugin(compilation, { concurrency: 3 });

    expect(emittedNames(compilation).sort()).toEqual(
      Object.keys(assets)
        .map((name) => `${name}.gz`)
        .sort(),
    );
  });
});
