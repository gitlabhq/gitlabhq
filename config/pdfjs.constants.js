const path = require('path');

const ROOT_PATH = path.resolve(__dirname, '..');
const WEBPACK_OUTPUT_PATH = path.join(ROOT_PATH, 'public/assets/webpack');
const WEBPACK_PUBLIC_PATH = '/assets/webpack/';

const PDFJS_PACKAGE_V3 = 'pdfjs-dist-v3';
const PDFJS_PACKAGE_V4 = 'pdfjs-dist-v4';

const PDF_JS_V3_VERSION = require('pdfjs-dist-v3/package.json').version;
const PDF_JS_V4_VERSION = require('pdfjs-dist-v4/package.json').version;

const PDF_JS_WORKER_V3_FILE_NAME = 'pdf.worker.min.js';
const PDF_JS_WORKER_V4_FILE_NAME = 'pdf.worker.min.mjs';
const PDF_JS_WORKER_V3_PATH = path.join('pdfjs', PDF_JS_V3_VERSION, '/');
const PDF_JS_WORKER_V4_PATH = path.join('pdfjs', PDF_JS_V4_VERSION, '/');
const PDF_JS_WORKER_V3_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, PDF_JS_WORKER_V3_PATH);
const PDF_JS_WORKER_V4_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, PDF_JS_WORKER_V4_PATH);
const PDF_JS_WORKER_V3_PUBLIC_PATH = path.join(
  WEBPACK_PUBLIC_PATH,
  PDF_JS_WORKER_V3_PATH,
  PDF_JS_WORKER_V3_FILE_NAME,
);
const PDF_JS_WORKER_V4_PUBLIC_PATH = path.join(
  WEBPACK_PUBLIC_PATH,
  PDF_JS_WORKER_V4_PATH,
  PDF_JS_WORKER_V4_FILE_NAME,
);
const PDF_JS_CMAPS_V3_PATH = path.join('pdfjs', PDF_JS_V3_VERSION, 'cmaps/');
const PDF_JS_CMAPS_V4_PATH = path.join('pdfjs', PDF_JS_V4_VERSION, 'cmaps/');
const PDF_JS_CMAPS_V3_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, PDF_JS_CMAPS_V3_PATH);
const PDF_JS_CMAPS_V4_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, PDF_JS_CMAPS_V4_PATH);
const PDF_JS_CMAPS_V3_PUBLIC_PATH = path.join(WEBPACK_PUBLIC_PATH, PDF_JS_CMAPS_V3_PATH);
const PDF_JS_CMAPS_V4_PUBLIC_PATH = path.join(WEBPACK_PUBLIC_PATH, PDF_JS_CMAPS_V4_PATH);

const pdfJsCopyFilesPatterns = [
  {
    from: path.join(ROOT_PATH, 'node_modules', PDFJS_PACKAGE_V4, 'cmaps'),
    to: PDF_JS_CMAPS_V4_OUTPUT_PATH,
  },
  {
    from: path.join(ROOT_PATH, 'node_modules', PDFJS_PACKAGE_V3, 'cmaps'),
    to: PDF_JS_CMAPS_V3_OUTPUT_PATH,
  },
  {
    from: path.join(
      ROOT_PATH,
      'node_modules',
      PDFJS_PACKAGE_V4,
      'legacy',
      'build',
      PDF_JS_WORKER_V4_FILE_NAME,
    ),
    to: PDF_JS_WORKER_V4_OUTPUT_PATH,
  },
  {
    from: path.join(
      ROOT_PATH,
      'node_modules',
      PDFJS_PACKAGE_V3,
      'legacy',
      'build',
      PDF_JS_WORKER_V3_FILE_NAME,
    ),
    to: PDF_JS_WORKER_V3_OUTPUT_PATH,
  },
];

module.exports = {
  pdfJsCopyFilesPatterns,
  PDF_JS_WORKER_V3_PUBLIC_PATH,
  PDF_JS_WORKER_V4_PUBLIC_PATH,
  PDF_JS_CMAPS_V3_PUBLIC_PATH,
  PDF_JS_CMAPS_V4_PUBLIC_PATH,
};
