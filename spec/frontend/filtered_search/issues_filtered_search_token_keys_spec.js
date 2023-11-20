import IssuableFilteredSearchTokenKeys, {
  createFilteredSearchTokenKeys,
} from '~/filtered_search/issuable_filtered_search_token_keys';

describe('Issues Filtered Search Token Keys', () => {
  describe('get', () => {
    let tokenKeys;

    beforeEach(() => {
      tokenKeys = IssuableFilteredSearchTokenKeys.get();
    });

    it('should return tokenKeys', () => {
      expect(tokenKeys).not.toBeNull();
    });

    it('should return tokenKeys as an array', () => {
      expect(tokenKeys instanceof Array).toBe(true);
    });

    it('should always return the same array', () => {
      const tokenKeys2 = IssuableFilteredSearchTokenKeys.get();

      expect(tokenKeys).toEqual(tokenKeys2);
    });

    it('should return assignee as a string', () => {
      const assignee = tokenKeys.find((tokenKey) => tokenKey.key === 'assignee');

      expect(assignee.type).toEqual('string');
    });
  });

  describe('getKeys', () => {
    it('should return keys', () => {
      const getKeys = IssuableFilteredSearchTokenKeys.getKeys();
      const keys = IssuableFilteredSearchTokenKeys.get().map((i) => i.key);

      keys.forEach((key, i) => {
        expect(key).toEqual(getKeys[i]);
      });
    });
  });

  describe('getConditions', () => {
    let conditions;

    beforeEach(() => {
      conditions = IssuableFilteredSearchTokenKeys.getConditions();
    });

    it('should return conditions', () => {
      expect(conditions).not.toBeNull();
    });

    it('should return conditions as an array', () => {
      expect(conditions instanceof Array).toBe(true);
    });
  });

  describe('searchByKey', () => {
    it('should return null when key not found', () => {
      const tokenKey = IssuableFilteredSearchTokenKeys.searchByKey('notakey');

      expect(tokenKey).toBeNull();
    });

    it('should return tokenKey when found by key', () => {
      const tokenKeys = IssuableFilteredSearchTokenKeys.get();
      const result = IssuableFilteredSearchTokenKeys.searchByKey(tokenKeys[0].key);

      expect(result).toEqual(tokenKeys[0]);
    });
  });

  describe('searchBySymbol', () => {
    it('should return null when symbol not found', () => {
      const tokenKey = IssuableFilteredSearchTokenKeys.searchBySymbol('notasymbol');

      expect(tokenKey).toBeNull();
    });

    it('should return tokenKey when found by symbol', () => {
      const tokenKeys = IssuableFilteredSearchTokenKeys.get();
      const result = IssuableFilteredSearchTokenKeys.searchBySymbol(tokenKeys[0].symbol);

      expect(result).toEqual(tokenKeys[0]);
    });
  });

  describe('searchByKeyParam', () => {
    it('should return null when key param not found', () => {
      const tokenKey = IssuableFilteredSearchTokenKeys.searchByKeyParam('notakeyparam');

      expect(tokenKey).toBeNull();
    });

    it('should return tokenKey when found by key param', () => {
      const tokenKeys = IssuableFilteredSearchTokenKeys.get();
      const result = IssuableFilteredSearchTokenKeys.searchByKeyParam(
        `${tokenKeys[0].key}_${tokenKeys[0].param}`,
      );

      expect(result).toEqual(tokenKeys[0]);
    });

    it('should return alternative tokenKey when found by key param', () => {
      const tokenKeys = IssuableFilteredSearchTokenKeys.getAlternatives();
      const result = IssuableFilteredSearchTokenKeys.searchByKeyParam(
        `${tokenKeys[0].key}_${tokenKeys[0].param}`,
      );

      expect(result).toEqual(tokenKeys[0]);
    });
  });

  describe('searchByConditionUrl', () => {
    it('should return null when condition url not found', () => {
      const condition = IssuableFilteredSearchTokenKeys.searchByConditionUrl(null);

      expect(condition).toBeNull();
    });

    it('should return condition when found by url', () => {
      const conditions = IssuableFilteredSearchTokenKeys.getConditions();
      const result = IssuableFilteredSearchTokenKeys.searchByConditionUrl(conditions[0].url);

      expect(result).toBe(conditions[0]);
    });
  });

  describe('searchByConditionKeyValue', () => {
    it('should return null when condition tokenKey and value not found', () => {
      const condition = IssuableFilteredSearchTokenKeys.searchByConditionKeyValue(null, null);

      expect(condition).toBeNull();
    });

    it('should return condition when found by tokenKey and value', () => {
      const conditions = IssuableFilteredSearchTokenKeys.getConditions();
      const result = IssuableFilteredSearchTokenKeys.searchByConditionKeyValue(
        conditions[0].tokenKey,
        conditions[0].operator,
        conditions[0].value,
      );

      expect(result).toEqual(conditions[0]);
    });
  });

  describe('removeTokensForKeys', () => {
    let initTokenKeys;

    beforeEach(() => {
      initTokenKeys = [...IssuableFilteredSearchTokenKeys.get()];
    });

    it('should remove the tokenKeys corresponding to the given keys', () => {
      const [firstTokenKey, secondTokenKey, ...restTokens] = initTokenKeys;
      IssuableFilteredSearchTokenKeys.removeTokensForKeys(firstTokenKey.key, secondTokenKey.key);

      expect(IssuableFilteredSearchTokenKeys.get()).toEqual(restTokens);
    });

    it('should do nothing when key is not found', () => {
      IssuableFilteredSearchTokenKeys.removeTokensForKeys('bogus');

      expect(IssuableFilteredSearchTokenKeys.get()).toEqual(initTokenKeys);
    });
  });
});

describe('createFilteredSearchTokenKeys', () => {
  describe.each(['Release'])('when $filter is disabled', (filter) => {
    let tokens;

    beforeEach(() => {
      tokens = createFilteredSearchTokenKeys({
        [`disable${filter}Filter`]: true,
      });
    });

    it('excludes the filter', () => {
      expect(tokens.tokenKeys).not.toContainEqual(
        expect.objectContaining({ tag: filter.toLowerCase() }),
      );
    });
  });
});
