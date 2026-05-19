import { __ } from '~/locale';
import { OAUTH_CALLBACK_MESSAGE_TYPE } from '~/jira_connect/subscriptions/constants';

function getOriginURL() {
  const origin = new URL(window.opener.location);
  origin.hash = '';
  origin.search = '';

  return origin;
}

function postMessageToJiraConnectApp(data) {
  window.opener.postMessage(
    { ...data, type: OAUTH_CALLBACK_MESSAGE_TYPE },
    getOriginURL().toString(),
  );
}

function initOAuthCallbacks() {
  if (!window.opener) {
    document.body.textContent = __(
      'This page must be opened from the GitLab for Jira Cloud app. You can close this window.',
    );
    return;
  }

  const params = new URLSearchParams(window.location.search);
  if (params.has('code') && params.has('state')) {
    postMessageToJiraConnectApp({
      success: true,
      code: params.get('code'),
      state: params.get('state'),
    });
  } else {
    postMessageToJiraConnectApp({ success: false });
  }

  window.close();
}

initOAuthCallbacks();
