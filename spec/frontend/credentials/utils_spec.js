import { initializeValuesFromQuery, goTo } from '~/credentials/utils';
import { visitUrl, getBaseURL } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('initializeValuesFromQuery', () => {
  describe('when no query parameters', () => {
    it('returns default sorting and tokens', () => {
      const { sorting, tokens } = initializeValuesFromQuery('');

      expect(sorting).toMatchObject({ value: 'expires', isAsc: true });
      expect(tokens).toMatchObject([]);
    });
  });

  describe('when query parameters present', () => {
    describe('sorting', () => {
      it('returns correct value', () => {
        const { sorting } = initializeValuesFromQuery('sort=created_asc');

        expect(sorting).toMatchObject({ value: 'created', isAsc: true });
      });

      it('returns correct sorting direction', () => {
        const { sorting } = initializeValuesFromQuery('sort=name_desc');

        expect(sorting).toMatchObject({ value: 'name', isAsc: false });
      });
    });

    describe('tokens', () => {
      it('returns correct value for filters ending on "before"', () => {
        const { tokens } = initializeValuesFromQuery('created_before=2025-01-01');

        expect(tokens).toMatchObject([
          { type: 'created', value: { data: '2025-01-01', operator: '<' } },
        ]);
      });

      it('returns correct value for filters ending on "after"', () => {
        const { tokens } = initializeValuesFromQuery('last_used_after=2024-01-01');

        expect(tokens).toMatchObject([
          { type: 'last_used', value: { data: '2024-01-01', operator: '≥' } },
        ]);
      });

      it('returns correct value for known filters', () => {
        const { tokens } = initializeValuesFromQuery('filter=ssh_keys');

        expect(tokens).toMatchObject([
          { type: 'filter', value: { data: 'ssh_keys', operator: '=' } },
        ]);
      });

      it('ignores unknown filters', () => {
        const { tokens } = initializeValuesFromQuery('unknown=dummy');

        expect(tokens).toMatchObject([]);
      });

      it('returns correct search term', () => {
        const { tokens } = initializeValuesFromQuery('search=my search term');

        expect(tokens).toMatchObject(['my search term']);
      });
    });
  });
});

describe('goTo', () => {
  it('reset pagination and contains sorting', () => {
    goTo('name', true, []);

    expect(visitUrl).toHaveBeenCalledWith(`${getBaseURL()}/?page=1&sort=name_asc`);
  });

  it('contains search term', () => {
    goTo('name', true, ['myterm']);

    expect(visitUrl).toHaveBeenCalledWith(`${getBaseURL()}/?page=1&search=myterm&sort=name_asc`);
  });

  it('contains filter term ending in "before"', () => {
    goTo('name', true, [{ type: 'created', value: { data: '2025-01-01', operator: '<' } }]);

    expect(visitUrl).toHaveBeenCalledWith(
      `${getBaseURL()}/?page=1&created_before=2025-01-01&sort=name_asc`,
    );
  });

  it('contains filter term ending in "after"', () => {
    goTo('name', true, [{ type: 'expires', value: { data: '2025-01-01', operator: '≥' } }]);

    expect(visitUrl).toHaveBeenCalledWith(
      `${getBaseURL()}/?page=1&expires_after=2025-01-01&sort=name_asc`,
    );
  });

  it('contains filters not ending in "before" or "after"', () => {
    goTo('name', true, [{ type: 'filter', value: { data: 'ssh_keys', operator: '=' } }]);

    expect(visitUrl).toHaveBeenCalledWith(`${getBaseURL()}/?page=1&filter=ssh_keys&sort=name_asc`);
  });
});
