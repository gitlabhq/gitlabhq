import * as getters from '~/error_tracking/store/getters';

describe('Error Tracking getters', () => {
  let state;

  const mockErrors = [
    { title: 'ActiveModel::MissingAttributeError: missing attribute: encrypted_password' },
    { title: 'Grape::Exceptions::MethodNotAllowed: Grape::Exceptions::MethodNotAllowed' },
    { title: 'NoMethodError: undefined method `sanitize_http_headers=' },
    { title: 'NoMethodError: undefined method `pry' },
  ];

  beforeEach(() => {
    state = {
      errors: mockErrors,
    };
  });

  describe('search results', () => {
    it('should return errors filtered by words in title matching the query', () => {
      const filteredErrors = getters.filterErrorsByTitle(state)('NoMethod');

      expect(filteredErrors).not.toContainEqual(mockErrors[0]);
      expect(filteredErrors.length).toBe(2);
    });

    it('should not return results if there is no matching query', () => {
      const filteredErrors = getters.filterErrorsByTitle(state)('GitLab');

      expect(filteredErrors.length).toBe(0);
    });
  });
});
