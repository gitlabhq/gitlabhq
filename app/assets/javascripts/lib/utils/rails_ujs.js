import Rails from '@rails/ujs';

export const initRails = () => {
  // eslint-disable-next-line no-underscore-dangle
  if (!window._rails_loaded) {
    Rails.start();

    // Count XHR requests for tests. See spec/support/helpers/wait_for_requests.rb
    window.pendingRailsUJSRequests = 0;
    document.body.addEventListener('ajax:complete', () => {
      window.pendingRailsUJSRequests -= 1;
    });

    document.body.addEventListener('ajax:beforeSend', () => {
      window.pendingRailsUJSRequests += 1;
    });
  }
};

export { Rails };
