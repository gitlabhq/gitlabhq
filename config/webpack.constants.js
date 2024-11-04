const path = require('path');

const ROOT_PATH = path.resolve(__dirname, '..');
const WEBPACK_OUTPUT_PATH = path.join(ROOT_PATH, 'public/assets/webpack');
const WEBPACK_PUBLIC_PATH = '/assets/webpack/';
const SOURCEGRAPH_VERSION = require('@sourcegraph/code-host-integration/package.json').version;

const SOURCEGRAPH_PATH = path.join('sourcegraph', SOURCEGRAPH_VERSION, '/');
const SOURCEGRAPH_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, SOURCEGRAPH_PATH);
const SOURCEGRAPH_PUBLIC_PATH = path.join(WEBPACK_PUBLIC_PATH, SOURCEGRAPH_PATH);

const GITLAB_WEB_IDE_VERSION = require('@gitlab/web-ide/package.json').version;

const { pdfJsCopyFilesPatterns } = require('./pdfjs.constants');

const GITLAB_WEB_IDE_PATH = path.join('gitlab-vscode', GITLAB_WEB_IDE_VERSION, '/');
const GITLAB_WEB_IDE_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, GITLAB_WEB_IDE_PATH);
const GITLAB_WEB_IDE_PUBLIC_PATH = path.join(WEBPACK_PUBLIC_PATH, GITLAB_WEB_IDE_PATH);

const IS_EE = require('./helpers/is_ee_env');
const IS_JH = require('./helpers/is_jh_env');

const SOURCEGRAPH_PACKAGE = '@sourcegraph/code-host-integration';
const GITLAB_WEB_IDE_PACKAGE = '@gitlab/web-ide';

const copyFilesPatterns = [
  ...pdfJsCopyFilesPatterns,
  {
    from: path.join(ROOT_PATH, 'node_modules', SOURCEGRAPH_PACKAGE, '/'),
    to: SOURCEGRAPH_OUTPUT_PATH,
    globOptions: {
      ignore: ['package.json'],
    },
  },
  {
    from: path.join(ROOT_PATH, 'node_modules', GITLAB_WEB_IDE_PACKAGE, 'dist', 'public'),
    to: GITLAB_WEB_IDE_OUTPUT_PATH,
  },
];

module.exports = {
  IS_EE,
  IS_JH,
  ROOT_PATH,
  WEBPACK_OUTPUT_PATH,
  WEBPACK_PUBLIC_PATH,
  SOURCEGRAPH_PUBLIC_PATH,
  GITLAB_WEB_IDE_PUBLIC_PATH,
  copyFilesPatterns,
};
