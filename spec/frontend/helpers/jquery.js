import $ from 'jquery';

// Expose jQuery so specs using jQuery plugins can be imported nicely.
// Here is an issue to explore better alternatives:
// https://gitlab.com/gitlab-org/gitlab/issues/12448
global.$ = $;
global.jQuery = $;

// Fail tests for unmocked requests
$.ajax = () => {
  const err = new Error(
    'Unexpected unmocked jQuery.ajax() call! Make sure to mock jQuery.ajax() in tests.',
  );
  global.fail(err);
  throw err;
};

export default $;
