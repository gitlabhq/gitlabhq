import {
  setReviewersForList,
  getReviewersForList,
  suggestedPosition,
} from '~/merge_requests/utils/reviewer_positions';

describe('reviewer_positions utility', () => {
  const mockIssuableId = '123';
  const mockListId = 'test-list-id';
  const mockReviewers = ['user1', 'user2', 'user3'];
  const mockReviewersString = '["user1","user2","user3"]';
  let setSpy;

  beforeEach(() => {
    const mockSessionStorage = {
      setItem: jest.fn(),
      getItem: jest.fn().mockImplementation((key) => {
        const vals = {
          'MergeRequest/123/test-list-id': mockReviewersString,
        };

        return vals[key];
      }),
    };

    Object.defineProperty(window, 'sessionStorage', {
      value: mockSessionStorage,
      writable: true,
    });

    setSpy = mockSessionStorage.setItem;
  });

  describe('setReviewersForList', () => {
    it('stores reviewers in session storage with the correct key', () => {
      setReviewersForList({
        issuableId: mockIssuableId,
        listId: mockListId,
        reviewers: mockReviewers,
      });

      expect(setSpy).toHaveBeenCalledWith(
        `MergeRequest/${mockIssuableId}/${mockListId}`,
        mockReviewersString,
      );
    });
  });

  describe('getReviewersForList', () => {
    it('retrieves reviewers from session storage with the correct key', () => {
      const result = getReviewersForList({
        issuableId: mockIssuableId,
        listId: mockListId,
      });

      expect(result).toEqual(mockReviewers);
    });

    it('returns an empty array when no data exists in storage', () => {
      const result = getReviewersForList({
        issuableId: 'some-issuable-id-that-doesnt-exist',
        listId: 'some-list-that-doesnt-exist',
      });

      expect(result).toEqual([]);
    });
  });

  describe('suggestedPosition', () => {
    it('returns the 1-indexed position of a username in the list', () => {
      const result = suggestedPosition({
        username: 'user2',
        list: mockReviewers,
      });

      expect(result).toBe(2);
    });

    it('returns 0 when the username is not in the list', () => {
      const result = suggestedPosition({
        username: 'nonexistent-user',
        list: mockReviewers,
      });

      expect(result).toBe(0);
    });

    it('returns 0 when the list is empty', () => {
      const result = suggestedPosition({
        username: 'user1',
        list: [],
      });

      expect(result).toBe(0);
    });

    it('handles undefined parameters gracefully', () => {
      const result = suggestedPosition();

      expect(result).toBe(0);
    });
  });
});
