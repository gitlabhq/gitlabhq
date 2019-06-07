import { __ } from '~/locale';

class RecentSearchesServiceError {
  constructor(message) {
    this.name = 'RecentSearchesServiceError';
    this.message = message || __('Recent Searches Service is unavailable');
  }
}

// Can't use `extends` for builtin prototypes and get true inheritance yet
RecentSearchesServiceError.prototype = Error.prototype;

export default RecentSearchesServiceError;
