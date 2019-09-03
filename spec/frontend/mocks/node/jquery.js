/* eslint-disable import/no-commonjs */

const $ = jest.requireActual('jquery');

// Fail tests for unmocked requests
$.ajax = () => {
  const err = new Error(
    'Unexpected unmocked jQuery.ajax() call! Make sure to mock jQuery.ajax() in tests.',
  );
  global.fail(err);
  throw err;
};

// jquery is not an ES6 module
module.exports = $;
