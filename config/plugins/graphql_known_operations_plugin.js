/* eslint-disable no-underscore-dangle */
const yaml = require('js-yaml');

const { evaluateModuleFromSource } = require('../helpers/evaluate_module_from_source');

const PLUGIN_NAME = 'GraphqlKnownOperationsPlugin';
const SUPPORTED_OPS = ['query', 'mutation', 'subscription'];
/* eslint-disable no-useless-escape */
const GRAPHQL_PATH_REGEX = new RegExp(`(${SUPPORTED_OPS.join('|')})\.graphql$`);

/**
 * Returns whether a given webpack module is a "graphql" module
 */
const isGraphqlModule = (module) => {
  return GRAPHQL_PATH_REGEX.test(module.resource);
};

/**
 * Returns graphql operation names we can parse from the given module
 *
 * Since webpack gives us the source **after** the graphql-tag/loader runs,
 * we can look for specific lines we're guaranteed to have from the
 * graphql-tag/loader.
 */
const getOperationNames = (module) => {
  const originalSource = module.originalSource();

  if (!originalSource) {
    return [];
  }

  const { exports: moduleExports } = evaluateModuleFromSource(originalSource.source().toString(), {
    // what: stub require(...) when evaluating the graphql module
    // why: require(...) is used to fetch fragments. We only need operation metadata, so it's fine to stub these out.
    require: () => ({ definitions: [] }),
  });

  const names = moduleExports.definitions
    .filter((x) => SUPPORTED_OPS.includes(x.operation))
    .map((x) => x.name?.value)
    // why: It's possible for operations to not have a name. That violates our eslint rule, but either way, let's ignore those here.
    .filter(Boolean);

  return names;
};

const createFileContents = (knownOperations) => {
  const sourceData = Array.from(knownOperations.values()).sort((a, b) => a.localeCompare(b));

  return yaml.dump(sourceData);
};

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

const onSucceedModule = ({ module, knownOperations }) => {
  if (!isGraphqlModule(module)) {
    return;
  }

  getOperationNames(module).forEach((name) => knownOperations.add(name));
};

const onCompilerEmit = ({ compilation, knownOperations, filename }) => {
  const contents = createFileContents(knownOperations);
  const source = createWebpackRawSource(contents);

  const asset = compilation.getAsset(filename);
  if (asset) {
    compilation.updateAsset(filename, source);
  } else {
    compilation.emitAsset(filename, source);
  }
};

/**
 * Webpack plugin that outputs a file containing known graphql operations.
 *
 * A lot of the mechanices was expired from [this example][1].
 *
 * [1]: https://sourcegraph.com/github.com/FormidableLabs/webpack-stats-plugin@e050ff8c362d5ddd45c66ade724d4a397ace3e5c/-/blob/lib/stats-writer-plugin.js?L136
 */
class GraphqlKnownOperationsPlugin {
  constructor({ filename }) {
    this._filename = filename;
  }

  apply(compiler) {
    const knownOperations = new Set();

    compiler.hooks.emit.tap(PLUGIN_NAME, (compilation) => {
      onCompilerEmit({
        compilation,
        knownOperations,
        filename: this._filename,
      });
    });

    compiler.hooks.compilation.tap(PLUGIN_NAME, (compilation) => {
      compilation.hooks.succeedModule.tap(PLUGIN_NAME, (module) => {
        onSucceedModule({
          module,
          knownOperations,
        });
      });
    });
  }
}

module.exports = GraphqlKnownOperationsPlugin;
