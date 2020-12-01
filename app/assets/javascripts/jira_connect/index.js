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

  const reqFailed = res => {
    // eslint-disable-next-line no-alert
    alert(res.responseJSON.error);
  };

  AP.getLocation(location => {
    $('.js-jira-connect-sign-in').each(() => {
      const updatedLink = `${$(this).attr('href')}?return_to=${location}`;
      $(this).attr('href', updatedLink);
    });
  });

  $('#add-subscription-form').on('submit', e => {
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
        .fail(reqFailed);
    });
  });

  $('.remove-subscription').on('click', e => {
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
        .fail(reqFailed);
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
