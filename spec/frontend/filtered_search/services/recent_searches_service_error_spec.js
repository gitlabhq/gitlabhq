import RecentSearchesServiceError from '~/filtered_search/services/recent_searches_service_error';

describe('RecentSearchesServiceError', () => {
  let recentSearchesServiceError;

  beforeEach(() => {
    recentSearchesServiceError = new RecentSearchesServiceError();
  });

  it('instantiates an instance of RecentSearchesServiceError and not an Error', () => {
    expect(recentSearchesServiceError).toEqual(expect.any(RecentSearchesServiceError));
    expect(recentSearchesServiceError.name).toBe('RecentSearchesServiceError');
  });

  it('should set a default message', () => {
    expect(recentSearchesServiceError.message).toBe('Recent Searches Service is unavailable');
  });
});
