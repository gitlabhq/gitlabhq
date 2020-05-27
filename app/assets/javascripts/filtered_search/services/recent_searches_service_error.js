import { __ } from '~/locale';

class RecentSearchesServiceError extends Error {
  constructor(message) {
    super(message || __('Recent Searches Service is unavailable'));
    this.name = 'RecentSearchesServiceError';
  }
}

export default RecentSearchesServiceError;
