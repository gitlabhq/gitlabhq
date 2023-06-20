const FIXTURES_PATH = `/fixtures`;
const TEST_HOST = 'http://test.host';
const DRAWIO_ORIGIN = 'https://embed.diagrams.net';

const DUMMY_IMAGE_URL = `${FIXTURES_PATH}/static/images/one_white_pixel.png`;

const GREEN_BOX_IMAGE_URL = `${FIXTURES_PATH}/static/images/green_box.png`;
const RED_BOX_IMAGE_URL = `${FIXTURES_PATH}/static/images/red_box.png`;

const DUMMY_IMAGE_BLOB_PATH = 'SpongeBlob.png';

// NOTE: module.exports is needed so that this file can be used
// by environment.js
//
// eslint-disable-next-line import/no-commonjs
module.exports = {
  FIXTURES_PATH,
  TEST_HOST,
  DRAWIO_ORIGIN,
  DUMMY_IMAGE_URL,
  GREEN_BOX_IMAGE_URL,
  RED_BOX_IMAGE_URL,
  DUMMY_IMAGE_BLOB_PATH,
};
