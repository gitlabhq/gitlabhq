import { GlPagination, GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import InactiveAccessTokenTableApp from '~/access_tokens/components/inactive_access_token_table_app.vue';
import { PAGE_SIZE } from '~/access_tokens/components/constants';
import { __, s__, sprintf } from '~/locale';

describe('~/access_tokens/components/inactive_access_token_table_app', () => {
  let wrapper;

  const accessTokenType = 'access token';
  const accessTokenTypePlural = 'access tokens';
  const information = undefined;
  const noInactiveTokensMessage = 'This resource has no inactive access tokens.';

  const defaultInactiveAccessTokens = [
    {
      name: 'a',
      scopes: ['api'],
      created_at: '2023-05-01T00:00:00.000Z',
      last_used_at: null,
      expired: true,
      expires_at: '2024-05-01T00:00:00.000Z',
      revoked: true,
      role: 'Maintainer',
    },
    {
      name: 'b',
      scopes: ['api', 'sudo'],
      created_at: '2024-04-21T00:00:00.000Z',
      last_used_at: '2024-04-21T00:00:00.000Z',
      expired: true,
      expires_at: new Date().toISOString(),
      revoked: false,
      role: 'Maintainer',
    },
  ];

  const createComponent = (props = {}) => {
    wrapper = mountExtended(InactiveAccessTokenTableApp, {
      provide: {
        accessTokenType,
        accessTokenTypePlural,
        information,
        initialInactiveAccessTokens: defaultInactiveAccessTokens,
        noInactiveTokensMessage,
        ...props,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => findTable().findAll('th > div > span');
  const findCells = () => findTable().findAll('td');
  const findPagination = () => wrapper.findComponent(GlPagination);

  it('should render an empty table with a default message', () => {
    createComponent({ initialInactiveAccessTokens: [] });

    const cells = findCells();
    expect(cells).toHaveLength(1);
    expect(cells.at(0).text()).toBe(
      sprintf(__('This resource has no inactive %{accessTokenTypePlural}.'), {
        accessTokenTypePlural,
      }),
    );
  });

  it('should render an empty table with a custom message', () => {
    const noTokensMessage = 'This group has no inactive access tokens.';
    createComponent({ initialInactiveAccessTokens: [], noInactiveTokensMessage: noTokensMessage });

    const cells = findCells();
    expect(cells).toHaveLength(1);
    expect(cells.at(0).text()).toBe(noTokensMessage);
  });

  describe('table headers', () => {
    it('has expected columns', () => {
      createComponent();

      const headers = findHeaders();
      expect(headers.wrappers.map((header) => header.text())).toStrictEqual([
        __('Token name'),
        __('Scopes'),
        s__('AccessTokens|Created'),
        'Last Used',
        __('Expired'),
        __('Role'),
      ]);
    });
  });

  it('`Last Used` header should contain a link and an assistive message', () => {
    createComponent();

    const headers = wrapper.findAll('th');
    const lastUsed = headers.at(3);
    const anchor = lastUsed.find('a');
    const assistiveElement = lastUsed.find('.gl-sr-only');
    expect(anchor.exists()).toBe(true);
    expect(anchor.attributes('href')).toBe(
      '/help/user/profile/personal_access_tokens.md#view-the-last-time-a-token-was-used',
    );
    expect(assistiveElement.text()).toBe(s__('AccessTokens|The last time a token was used'));
  });

  it('sorts rows alphabetically', async () => {
    createComponent();

    const cells = findCells();

    // First and second rows
    expect(cells.at(0).text()).toBe('a');
    expect(cells.at(6).text()).toBe('b');

    const headers = findHeaders();
    await headers.at(0).trigger('click');
    await headers.at(0).trigger('click');

    // First and second rows have swapped
    expect(cells.at(0).text()).toBe('b');
    expect(cells.at(6).text()).toBe('a');
  });

  it('sorts rows by last used date', async () => {
    createComponent();

    const cells = findCells();

    // First and second rows
    expect(cells.at(0).text()).toBe('a');
    expect(cells.at(6).text()).toBe('b');

    const headers = findHeaders();
    await headers.at(3).trigger('click');

    // First and second rows have swapped
    expect(cells.at(0).text()).toBe('b');
    expect(cells.at(6).text()).toBe('a');
  });

  it('sorts rows by expiry date', async () => {
    createComponent();

    const cells = findCells();
    const headers = findHeaders();
    await headers.at(4).trigger('click');

    // First and second rows have swapped
    expect(cells.at(0).text()).toBe('b');
    expect(cells.at(6).text()).toBe('a');
  });

  it('shows Revoked in expiry column when revoked', () => {
    createComponent();

    const cells = findCells();

    // First and second rows
    expect(cells.at(4).text()).toBe('Revoked');
    expect(cells.at(10).text()).toBe('Expired just now');
  });

  describe('pagination', () => {
    it('does not show pagination component', () => {
      createComponent({
        initialInactiveAccessTokens: Array(PAGE_SIZE).fill(defaultInactiveAccessTokens[0]),
      });

      expect(findPagination().exists()).toBe(false);
    });

    it('shows the pagination component', () => {
      createComponent({
        initialInactiveAccessTokens: Array(PAGE_SIZE + 1).fill(defaultInactiveAccessTokens[0]),
      });
      expect(findPagination().exists()).toBe(true);
    });
  });
});
