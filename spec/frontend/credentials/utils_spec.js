import { goTo } from '~/credentials/utils';
import { visitUrl, getBaseURL } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

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
