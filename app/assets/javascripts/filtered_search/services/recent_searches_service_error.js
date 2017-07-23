class RecentSearchesServiceError {
  constructor(message) {
    this.name = 'RecentSearchesServiceError';
    this.message = message || 'Recent Searches Service is unavailable';
  }
}

// Can't use `extends` for builtin prototypes and get true inheritance yet
RecentSearchesServiceError.prototype = Error.prototype;

export default RecentSearchesServiceError;
