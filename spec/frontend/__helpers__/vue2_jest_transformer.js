/* eslint-disable */
const path = require('path');
const { parseComponent, compileTemplate } = require(
  path.join(process.cwd(), 'node_modules/vue/packages/compiler-sfc/dist/compiler-sfc.js'),
);
const coffeescriptTransformer = require('@vue/vue2-jest/lib/transformers/coffee');
const _processStyle = require('@vue/vue2-jest/lib/process-style');
const processCustomBlocks = require('@vue/vue2-jest/lib/process-custom-blocks');
const getVueJestConfig = require('@vue/vue2-jest/lib/utils').getVueJestConfig;
const logResultErrors = require('@vue/vue2-jest/lib/utils').logResultErrors;
const stripInlineSourceMap = require('@vue/vue2-jest/lib/utils').stripInlineSourceMap;
const getCustomTransformer = require('@vue/vue2-jest/lib/utils').getCustomTransformer;
const loadSrc = require('@vue/vue2-jest/lib/utils').loadSrc;
const babelTransformer = require('babel-jest').default;
const generateCode = require('@vue/vue2-jest/lib/generate-code');

function resolveTransformer(lang = 'js', vueJestConfig) {
  const transformer = getCustomTransformer(vueJestConfig.transform, lang);
  if (/^typescript$|tsx?$/.test(lang)) {
    return transformer || require('@vue/vue2-jest/lib/transformers/typescript')(lang);
  }
  if (/^coffee$|coffeescript$/.test(lang)) {
    return transformer || coffeescriptTransformer;
  }
  return transformer || babelTransformer.createTransformer();
}

function resolveCompiler(vueJestConfig) {
  if (!vueJestConfig.compiler) {
    return undefined;
  }
  return typeof vueJestConfig.compiler === 'string'
    ? require(vueJestConfig.compiler)
    : vueJestConfig.compiler;
}

function processScript(scriptPart, filePath, config) {
  if (!scriptPart) {
    return null;
  }

  let externalSrc = null;
  if (scriptPart.src) {
    scriptPart.content = loadSrc(scriptPart.src, filePath);
    externalSrc = scriptPart.content;
  }

  const vueJestConfig = getVueJestConfig(config);
  const transformer = resolveTransformer(scriptPart.lang, vueJestConfig);

  const result = transformer.process(scriptPart.content, filePath, config);
  result.code = stripInlineSourceMap(result.code);
  result.externalSrc = externalSrc;
  return result;
}

function processTemplate(template, filename, config) {
  if (!template) {
    return null;
  }

  const vueJestConfig = getVueJestConfig(config);

  if (template.src) {
    template.content = loadSrc(template.src, filename);
  }

  const compiler = resolveCompiler(vueJestConfig);
  const userTemplateCompilerOptions = vueJestConfig.templateCompiler || {};
  const userCompilerOptions = userTemplateCompilerOptions.compilerOptions || {};

  const result = compileTemplate({
    source: template.content,
    compiler,
    filename,
    isFunctional: template.attrs.functional,
    preprocessLang: template.lang,
    preprocessOptions: vueJestConfig[template.lang],
    ...userTemplateCompilerOptions,
    compilerOptions: {
      optimize: false,
      ...userCompilerOptions,
      modules: [...(userCompilerOptions.modules || [])],
    },
  });

  logResultErrors(result);

  return result;
}

function processStyle(styles, filename, config) {
  if (!styles) {
    return null;
  }

  const filteredStyles = styles
    .filter((style) => style.module)
    .map((style) => ({
      code: _processStyle(style, filename, config),
      moduleName: style.module === true ? '$style' : style.module,
    }));

  return filteredStyles.length ? filteredStyles : null;
}

module.exports = {
  process(src, filename, config) {
    const descriptor = parseComponent(src, { filename });

    const templateResult = processTemplate(descriptor.template, filename, config);
    const scriptResult = processScript(descriptor.script, filename, config);
    const stylesResult = processStyle(descriptor.styles, filename, config);
    const customBlocksResult = processCustomBlocks(descriptor.customBlocks, filename, config);

    const isFunctional =
      (descriptor.template && descriptor.template.attrs && descriptor.template.attrs.functional) ||
      (descriptor.script &&
        descriptor.script.content &&
        /functional:\s*true/.test(descriptor.script.content));

    const output = generateCode(
      scriptResult,
      templateResult,
      stylesResult,
      customBlocksResult,
      isFunctional,
      filename,
    );

    return {
      code: output.code,
      map: output.map.toString(),
    };
  },
};
