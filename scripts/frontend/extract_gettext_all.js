const { program } = require('commander');

const { GettextExtractor, JsExtractors } = require('gettext-extractor');
const {
  decorateJSParserWithVueSupport,
  decorateExtractorWithHelpers,
} = require('gettext-extractor-vue');
const compilerSfc = require('@vue/compiler-sfc');
const vue3Template = require('../../config/vue3migration/compilers/vue3_template');
const { compatConfig } = require('../../app/assets/javascripts/lib/utils/vue3compat/compat_config');

// Compile templates the way the bundler does. The plain compiler crashes on some templates.
const vue3TemplateCompiler = {
  ...compilerSfc,
  compileTemplate: (options) =>
    compilerSfc.compileTemplate({
      ...options,
      compiler: vue3Template,
      compilerOptions: { whitespace: 'preserve', compatConfig },
    }),
};

program
  .option('-f, --file <file>', 'Extract message from one single file')
  .option('-a, --all', 'Extract message from all js/vue files')
  .parse(process.argv);

const args = program.opts();

const extractor = decorateExtractorWithHelpers(new GettextExtractor());

function ensureSingleLine(str) {
  // This guard makes the function significantly faster
  if (str.includes('\n') || str.includes('\r')) {
    return str
      .split(/\s*[\r\n]+\s*/)
      .filter((s) => s !== '')
      .join(' ');
  }
  return str;
}

extractor.addMessageTransformFunction(ensureSingleLine);

const jsParser = extractor.createJsParser([
  // Place all the possible expressions to extract here:
  JsExtractors.callExpression(['__', 's__'], {
    arguments: {
      text: 0,
    },
  }),
  JsExtractors.callExpression('n__', {
    arguments: {
      text: 0,
      textPlural: 1,
    },
  }),
]);

const vueParser = decorateJSParserWithVueSupport(jsParser, {
  vue3TemplateCompiler,
  // All of our expressions contain `__`.
  // So we can safely ignore parsing files _not_ containing it.
  guard: '__',
});

function printJson() {
  const messages = extractor.getMessages().reduce((acc, message) => {
    let { text } = message;
    if (message.textPlural) {
      text += `\u0000${message.textPlural}`;
    }

    message.references.forEach((reference) => {
      const filename = reference.replace(/:\d+$/, '');

      if (!Array.isArray(acc[filename])) {
        acc[filename] = [];
      }

      acc[filename].push([text, reference]);
    });

    return acc;
  }, {});

  console.log(JSON.stringify(messages));
}

async function main() {
  if (args.file) {
    return vueParser.parseFile(args.file).then(() => printJson());
  }

  if (args.all) {
    return vueParser
      .parseFilesGlob('{ee/app,app}/assets/javascripts/**/*.{js,vue}')
      .then(() => printJson());
  }

  throw new Error('ERROR: Please use the script correctly:');
}

main().catch((error) => {
  console.warn(error.message);
  program.outputHelp();
  process.exit(1);
});
