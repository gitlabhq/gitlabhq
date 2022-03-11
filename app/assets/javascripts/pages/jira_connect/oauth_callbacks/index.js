function getOriginURL() {
  const origin = new URL(window.opener.location);
  origin.hash = '';
  origin.search = '';

  return origin;
}

function postMessageToJiraConnectApp(data) {
  window.opener.postMessage(data, getOriginURL().toString());
}

function initOAuthCallbacks() {
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
