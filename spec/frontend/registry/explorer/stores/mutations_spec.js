import mutations from '~/registry/explorer/stores/mutations';
import * as types from '~/registry/explorer/stores/mutation_types';

describe('Mutations Registry Explorer Store', () => {
  let mockState;

  beforeEach(() => {
    mockState = {};
  });

  describe('SET_INITIAL_STATE', () => {
    it('should set the initial state', () => {
      const payload = {
        endpoint: 'foo',
        isGroupPage: '',
        expirationPolicy: { foo: 'bar' },
        isAdmin: '',
      };
      const expectedState = {
        ...mockState,
        config: { ...payload, isGroupPage: false, isAdmin: false },
      };
      mutations[types.SET_INITIAL_STATE](mockState, {
        ...payload,
        expirationPolicy: JSON.stringify(payload.expirationPolicy),
      });

      expect(mockState).toEqual(expectedState);
    });
  });

  describe('SET_IMAGES_LIST_SUCCESS', () => {
    it('should set the images list', () => {
      const images = [{ name: 'foo' }, { name: 'bar' }];
      const defaultStatus = { deleting: false, failedDelete: false };
      const expectedState = {
        ...mockState,
        images: [{ name: 'foo', ...defaultStatus }, { name: 'bar', ...defaultStatus }],
      };
      mutations[types.SET_IMAGES_LIST_SUCCESS](mockState, images);

      expect(mockState).toEqual(expectedState);
    });
  });

  describe('UPDATE_IMAGE', () => {
    it('should update an image', () => {
      mockState.images = [{ id: 1, name: 'foo' }, { id: 2, name: 'bar' }];
      const payload = { id: 1, name: 'baz' };
      const expectedState = {
        ...mockState,
        images: [payload, { id: 2, name: 'bar' }],
      };
      mutations[types.UPDATE_IMAGE](mockState, payload);

      expect(mockState).toEqual(expectedState);
    });
  });

  describe('SET_TAGS_LIST_SUCCESS', () => {
    it('should set the tags list', () => {
      const tags = [1, 2, 3];
      const expectedState = { ...mockState, tags };
      mutations[types.SET_TAGS_LIST_SUCCESS](mockState, tags);

      expect(mockState).toEqual(expectedState);
    });
  });

  describe('SET_MAIN_LOADING', () => {
    it('should set the isLoading', () => {
      const expectedState = { ...mockState, isLoading: true };
      mutations[types.SET_MAIN_LOADING](mockState, true);

      expect(mockState).toEqual(expectedState);
    });
  });

  describe('SET_SHOW_GARBAGE_COLLECTION_TIP', () => {
    it('should set the showGarbageCollectionTip', () => {
      const expectedState = { ...mockState, showGarbageCollectionTip: true };
      mutations[types.SET_SHOW_GARBAGE_COLLECTION_TIP](mockState, true);

      expect(mockState).toEqual(expectedState);
    });
  });

  describe('SET_PAGINATION', () => {
    const generatePagination = () => [
      {
        'X-PAGE': '1',
        'X-PER-PAGE': '20',
        'X-TOTAL': '100',
        'X-TOTAL-PAGES': '5',
        'X-NEXT-PAGE': '2',
        'X-PREV-PAGE': '0',
      },
      {
        page: 1,
        perPage: 20,
        total: 100,
        totalPages: 5,
        nextPage: 2,
        previousPage: 0,
      },
    ];

    it('should set the images pagination', () => {
      const [headers, expectedResult] = generatePagination();
      const expectedState = { ...mockState, pagination: expectedResult };
      mutations[types.SET_PAGINATION](mockState, headers);

      expect(mockState).toEqual(expectedState);
    });

    it('should set the tags pagination', () => {
      const [headers, expectedResult] = generatePagination();
      const expectedState = { ...mockState, tagsPagination: expectedResult };
      mutations[types.SET_TAGS_PAGINATION](mockState, headers);

      expect(mockState).toEqual(expectedState);
    });
  });
});
