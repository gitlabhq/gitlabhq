import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';

describe('Filtered Search Token Keys', () => {
  const tokenKeys = [
    {
      key: 'author',
      type: 'string',
      param: 'username',
      symbol: '@',
      icon: 'pencil',
      tag: '@author',
    },
  ];

  const conditions = [
    {
      url: 'assignee_id=0',
      tokenKey: 'assignee',
      value: 'none',
    },
  ];

  describe('get', () => {
    it('should return tokenKeys', () => {
      expect(new FilteredSearchTokenKeys().get()).not.toBeNull();
    });

    it('should return tokenKeys as an array', () => {
      expect(new FilteredSearchTokenKeys().get() instanceof Array).toBe(true);
    });
  });

  describe('getKeys', () => {
    it('should return keys', () => {
      const getKeys = new FilteredSearchTokenKeys(tokenKeys).getKeys();
      const keys = new FilteredSearchTokenKeys(tokenKeys).get().map(i => i.key);

      keys.forEach((key, i) => {
        expect(key).toEqual(getKeys[i]);
      });
    });
  });

  describe('getConditions', () => {
    it('should return conditions', () => {
      expect(new FilteredSearchTokenKeys().getConditions()).not.toBeNull();
    });

    it('should return conditions as an array', () => {
      expect(new FilteredSearchTokenKeys().getConditions() instanceof Array).toBe(true);
    });
  });

  describe('searchByKey', () => {
    it('should return null when key not found', () => {
      const tokenKey = new FilteredSearchTokenKeys(tokenKeys).searchByKey('notakey');

      expect(tokenKey).toBeNull();
    });

    it('should return tokenKey when found by key', () => {
      const result = new FilteredSearchTokenKeys(tokenKeys).searchByKey(tokenKeys[0].key);

      expect(result).toEqual(tokenKeys[0]);
    });
  });

  describe('searchBySymbol', () => {
    it('should return null when symbol not found', () => {
      const tokenKey = new FilteredSearchTokenKeys(tokenKeys).searchBySymbol('notasymbol');

      expect(tokenKey).toBeNull();
    });

    it('should return tokenKey when found by symbol', () => {
      const result = new FilteredSearchTokenKeys(tokenKeys).searchBySymbol(tokenKeys[0].symbol);

      expect(result).toEqual(tokenKeys[0]);
    });
  });

  describe('searchByKeyParam', () => {
    it('should return null when key param not found', () => {
      const tokenKey = new FilteredSearchTokenKeys(tokenKeys).searchByKeyParam('notakeyparam');

      expect(tokenKey).toBeNull();
    });

    it('should return tokenKey when found by key param', () => {
      const result = new FilteredSearchTokenKeys(tokenKeys).searchByKeyParam(
        `${tokenKeys[0].key}_${tokenKeys[0].param}`,
      );

      expect(result).toEqual(tokenKeys[0]);
    });

    it('should return alternative tokenKey when found by key param', () => {
      const result = new FilteredSearchTokenKeys(tokenKeys).searchByKeyParam(
        `${tokenKeys[0].key}_${tokenKeys[0].param}`,
      );

      expect(result).toEqual(tokenKeys[0]);
    });
  });

  describe('searchByConditionUrl', () => {
    it('should return null when condition url not found', () => {
      const condition = new FilteredSearchTokenKeys([], [], conditions).searchByConditionUrl(null);

      expect(condition).toBeNull();
    });

    it('should return condition when found by url', () => {
      const result = new FilteredSearchTokenKeys([], [], conditions).searchByConditionUrl(
        conditions[0].url,
      );

      expect(result).toBe(conditions[0]);
    });
  });

  describe('searchByConditionKeyValue', () => {
    it('should return null when condition tokenKey and value not found', () => {
      const condition = new FilteredSearchTokenKeys([], [], conditions).searchByConditionKeyValue(
        null,
        null,
        null,
      );

      expect(condition).toBeNull();
    });

    it('should return condition when found by tokenKey and value', () => {
      const result = new FilteredSearchTokenKeys([], [], conditions).searchByConditionKeyValue(
        conditions[0].tokenKey,
        conditions[0].operator,
        conditions[0].value,
      );

      expect(result).toEqual(conditions[0]);
    });
  });
});
