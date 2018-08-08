const argumentsParser = require('commander');

const { GettextExtractor, JsExtractors } = require('gettext-extractor');
const {
  decorateJSParserWithVueSupport,
  decorateExtractorWithHelpers,
} = require('gettext-extractor-vue');
const ensureSingleLine = require('../../app/assets/javascripts/locale/ensure_single_line.js');

const arguments = argumentsParser
  .option('-f, --file <file>', 'Extract message from one single file')
  .option('-a, --all', 'Extract message from all js/vue files')
  .parse(process.argv);

const extractor = decorateExtractorWithHelpers(new GettextExtractor());

extractor.addMessageTransformFunction(ensureSingleLine);

const jsParser = extractor.createJsParser([
  // Place all the possible expressions to extract here:
  JsExtractors.callExpression('__', {
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
  JsExtractors.callExpression('s__', {
    arguments: {
      text: 0,
    },
  }),
]);

const vueParser = decorateJSParserWithVueSupport(jsParser);

function printJson() {
  const messages = extractor.getMessages().reduce((result, message) => {
    let text = message.text;
    if (message.textPlural) {
      text += `\u0000${message.textPlural}`;
    }

    message.references.forEach(reference => {
      const filename = reference.replace(/:\d+$/, '');

      if (!Array.isArray(result[filename])) {
        result[filename] = [];
      }

      result[filename].push([text, reference]);
    });

    return result;
  }, {});

  console.log(JSON.stringify(messages));
}

if (arguments.file) {
  vueParser.parseFile(arguments.file).then(() => printJson());
} else if (arguments.all) {
  vueParser.parseFilesGlob('{ee/app,app}/assets/javascripts/**/*.{js,vue}').then(() => printJson());
} else {
  console.warn('ERROR: Please use the script correctly:');
  arguments.outputHelp();
  process.exit(1);
}
