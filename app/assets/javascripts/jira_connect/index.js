import Vue from 'vue';
import $ from 'jquery';
import App from './components/app.vue';

/**
 * Initialize necessary form handlers for the Jira Connect app
 */
const initJiraFormHandlers = () => {
  const reqComplete = () => {
    AP.navigator.reload();
  };

  const reqFailed = (res, fallbackErrorMessage) => {
    const { responseJSON: { error } = {} } = res || {};
    // eslint-disable-next-line no-alert
    alert(error || fallbackErrorMessage);
  };

  AP.getLocation(location => {
    $('.js-jira-connect-sign-in').each(function updateSignInLink() {
      const updatedLink = `${$(this).attr('href')}?return_to=${location}`;
      $(this).attr('href', updatedLink);
    });
  });

  $('#add-subscription-form').on('submit', function onAddSubscriptionForm(e) {
    const actionUrl = $(this).attr('action');
    e.preventDefault();

    AP.context.getToken(token => {
      // eslint-disable-next-line no-jquery/no-ajax
      $.post(actionUrl, {
        jwt: token,
        namespace_path: $('#namespace-input').val(),
        format: 'json',
      })
        .done(reqComplete)
        .fail(err => reqFailed(err, 'Failed to add namespace. Please try again.'));
    });
  });

  $('.remove-subscription').on('click', function onRemoveSubscriptionClick(e) {
    const href = $(this).attr('href');
    e.preventDefault();

    AP.context.getToken(token => {
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
        .fail(err => reqFailed(err, 'Failed to remove namespace. Please try again.'));
    });
  });
};

function initJiraConnect() {
  const el = document.querySelector('.js-jira-connect-app');

  initJiraFormHandlers();

  return new Vue({
    el,
    render(createElement) {
      return createElement(App, {});
    },
  });
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
