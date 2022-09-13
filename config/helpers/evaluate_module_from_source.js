const vm = require('vm');

/**
 * This function uses Node's `vm` modules to evaluate the `module.exports` of a given source string
 *
 * Example:
 *
 * ```javascript
 * const { exports: moduleExports } = evaluateModuleFromSource("const foo = 7;\n module.exports.bar = 10 + foo;");
 *
 * assert(moduleExports.bar === 17);
 * ```
 *
 * @param {String} source to be evaluated using Node's `vm` modules
 * @param {{ require: Function }} options used in the context during evaluation of the Node module
 * @returns {{ exports: any }} exports added to the script's `module.exports` context
 */
const evaluateModuleFromSource = (source, { require } = {}) => {
  const context = {
    module: {
      exports: {},
    },
    require,
  };

  try {
    const script = new vm.Script(source);
    script.runInNewContext(context);
  } catch (e) {
    console.error(e);
    throw e;
  }

  return context.module;
};

module.exports = { evaluateModuleFromSource };
