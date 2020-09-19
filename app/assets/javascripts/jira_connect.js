/* eslint-disable func-names, no-var, no-alert */
/* global $ */
/* global AP */

/**
 * This script is not going through Webpack bundling
 * as it is only included in `app/views/jira_connect/subscriptions/index.html.haml`
 * which is going to be rendered within iframe on Jira app dashboard
 * hence any code written here needs to be IE11+ compatible (no fully ES6)
 */

function onLoaded() {
  var reqComplete = function() {
    AP.navigator.reload();
  };

  var reqFailed = function(res) {
    alert(res.responseJSON.error);
  };

  $('#add-subscription-form').on('submit', function(e) {
    var actionUrl = $(this).attr('action');
    e.preventDefault();

    AP.context.getToken(function(token) {
      // eslint-disable-next-line no-jquery/no-ajax
      $.post(actionUrl, {
        jwt: token,
        namespace_path: $('#namespace-input').val(),
        format: 'json',
      })
        .done(reqComplete)
        .fail(reqFailed);
    });
  });

  $('.remove-subscription').on('click', function(e) {
    var href = $(this).attr('href');
    e.preventDefault();

    AP.context.getToken(function(token) {
      // eslint-disable-next-line no-jquery/no-ajax
      $.ajax({
        url: href,
        method: 'DELETE',
        data: {
          jwt: token,
          format: 'json',
        },
      })
        .done(reqComplete)
        .fail(reqFailed);
    });
  });
}
document.addEventListener('DOMContentLoaded', onLoaded);
