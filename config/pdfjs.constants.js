const path = require('path');

const ROOT_PATH = path.resolve(__dirname, '..');
const WEBPACK_OUTPUT_PATH = path.join(ROOT_PATH, 'public/assets/webpack');
const WEBPACK_PUBLIC_PATH = '/assets/webpack/';

const PDFJS_PACKAGE = 'pdfjs-dist';

const PDF_JS_VERSION = require('pdfjs-dist/package.json').version;

const PDF_JS_WORKER_FILE_NAME = 'pdf.worker.min.mjs';
const PDF_JS_WORKER_PATH = path.join('pdfjs', PDF_JS_VERSION, '/');
const PDF_JS_WORKER_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, PDF_JS_WORKER_PATH);

const PDF_JS_WORKER_PUBLIC_PATH = path.join(
  WEBPACK_PUBLIC_PATH,
  PDF_JS_WORKER_PATH,
  PDF_JS_WORKER_FILE_NAME,
);
const PDF_JS_CMAPS_PATH = path.join('pdfjs', PDF_JS_VERSION, 'cmaps/');
const PDF_JS_CMAPS_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, PDF_JS_CMAPS_PATH);
const PDF_JS_CMAPS_PUBLIC_PATH = path.join(WEBPACK_PUBLIC_PATH, PDF_JS_CMAPS_PATH);

const pdfJsCopyFilesPatterns = [
  {
    from: path.join(ROOT_PATH, 'node_modules', PDFJS_PACKAGE, 'cmaps'),
    to: PDF_JS_CMAPS_OUTPUT_PATH,
  },
  {
    from: path.join(
      ROOT_PATH,
      'node_modules',
      PDFJS_PACKAGE,
      'legacy',
      'build',
      PDF_JS_WORKER_FILE_NAME,
    ),
    to: PDF_JS_WORKER_OUTPUT_PATH,
  },
];

module.exports = {
  pdfJsCopyFilesPatterns,
  PDF_JS_WORKER_PUBLIC_PATH,
  PDF_JS_CMAPS_PUBLIC_PATH,
};
