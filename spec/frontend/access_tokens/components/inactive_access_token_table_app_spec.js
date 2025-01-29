import { GlPagination, GlTable } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import InactiveAccessTokenTableApp from '~/access_tokens/components/inactive_access_token_table_app.vue';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

describe('~/access_tokens/components/inactive_access_token_table_app', () => {
  let wrapper;
  let axiosMock;

  const noInactiveTokensMessage = 'This resource has no inactive access tokens.';
  const paginationUrl =
    'https://gitlab.example.com/groups/mygroup/-/settings/access_tokens/inactive.json';

  const defaultInactiveAccessTokens = [
    {
      name: 'a',
      description: 'Test description',
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
      description: 'Test description',
      scopes: ['api', 'sudo'],
      created_at: '2024-04-21T00:00:00.000Z',
      last_used_at: '2024-04-21T00:00:00.000Z',
      expired: true,
      expires_at: new Date().toISOString(),
      revoked: false,
      role: 'Maintainer',
    },
  ];

  const paginationHeaders = ({ page = 1, perPage = 20, total = 60 } = {}) => ({
    'X-Page': page,
    'X-Per-Page': perPage,
    'X-Total': total,
  });

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    axiosMock
      .onGet(`${paginationUrl}?page=1`)
      .replyOnce(HTTP_STATUS_OK, defaultInactiveAccessTokens, paginationHeaders());
  });

  afterEach(() => {
    axiosMock.restore();
  });

  const createComponent = (props = {}) => {
    wrapper = mountExtended(InactiveAccessTokenTableApp, {
      provide: {
        noInactiveTokensMessage,
        paginationUrl,
        ...props,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => findTable().findAll('thead th > div > span');
  const findCells = () => findTable().findAll('tbody td, tbody th');
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findPageOne = () => findPagination().find('ul > li');

  it('should render an empty table with a message', async () => {
    axiosMock.resetHandlers();
    axiosMock
      .onGet(`${paginationUrl}?page=1`)
      .replyOnce(HTTP_STATUS_OK, [], paginationHeaders({ total: 0 }));
    createComponent();

    const cells = findCells();
    expect(cells).toHaveLength(1);
    expect(cells.at(0).text()).toBe('');
    expect(findTable().attributes('aria-busy')).toBe('true');

    await axios.waitForAll();
    expect(cells.at(0).text()).toBe(noInactiveTokensMessage);
    expect(findTable().attributes('aria-busy')).toBe('false');
  });

  describe('table headers', () => {
    it('has expected columns', () => {
      createComponent();

      const headers = findHeaders();
      expect(headers.wrappers.map((header) => header.text())).toStrictEqual([
        'Token name',
        'Description',
        'Scopes',
        'Created',
        'Last Used',
        'Expired',
        'Role',
      ]);
    });
  });

  it('`Last Used` header should contain a link and an assistive message', () => {
    createComponent();

    const headers = wrapper.findAll('th');
    const lastUsed = headers.at(4);
    const anchor = lastUsed.find('a');
    const assistiveElement = lastUsed.find('.gl-sr-only');
    expect(anchor.exists()).toBe(true);
    expect(anchor.attributes('href')).toBe(
      '/help/user/profile/personal_access_tokens.md#view-the-time-at-and-ips-where-a-token-was-last-used',
    );
    expect(assistiveElement.text()).toBe('The last time a token was used');
  });

  it('does not sort rows', async () => {
    createComponent();
    await axios.waitForAll();

    const cells = findCells();

    // First and second rows
    expect(cells.at(0).text()).toBe('a');
    expect(cells.at(7).text()).toBe('b');

    const headers = findHeaders();
    await headers.at(0).trigger('click');
    await headers.at(0).trigger('click');

    // First and second rows have swapped
    expect(cells.at(0).text()).toBe('a');
    expect(cells.at(7).text()).toBe('b');
  });

  it('shows Revoked in expiry column when revoked', async () => {
    createComponent();
    await axios.waitForAll();

    const cells = findCells();

    // First and second rows
    expect(cells.at(5).text()).toBe('Revoked');
    expect(cells.at(12).text()).toBe('Expired just now');
  });

  describe('pagination', () => {
    it('does not show pagination component', async () => {
      axiosMock.resetHandlers();
      axiosMock
        .onGet()
        .replyOnce(HTTP_STATUS_OK, defaultInactiveAccessTokens, paginationHeaders({ total: 2 }));
      createComponent();
      await axios.waitForAll();

      expect(findPagination().exists()).toBe(false);
    });

    it('shows the pagination component', async () => {
      createComponent();
      await axios.waitForAll();

      expect(findPagination().exists()).toBe(true);
    });

    it('moves to the next page', async () => {
      createComponent();
      await axios.waitForAll();

      axiosMock
        .onGet(`${paginationUrl}?page=2`)
        .replyOnce(HTTP_STATUS_OK, [], paginationHeaders({ total: 0 }));
      findPagination().vm.$emit('input', 2);
      await nextTick();
      expect(findTable().attributes('aria-busy')).toBe('true');
      expect(findPageOne().classes('disabled')).toBe(true);

      await axios.waitForAll();
      expect(findTable().attributes('aria-busy')).toBe('false');
      expect(findCells().at(0).text()).toBe(noInactiveTokensMessage);
    });

    it('shows an error if it fails to fetch tokens', async () => {
      createComponent();
      await axios.waitForAll();

      axiosMock
        .onGet(`${paginationUrl}?page=2`)
        .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, defaultInactiveAccessTokens);
      findPagination().vm.$emit('input', 2);
      await nextTick();
      expect(findTable().attributes('aria-busy')).toBe('true');
      expect(findPageOne().classes('disabled')).toBe(true);

      await axios.waitForAll();
      expect(findTable().attributes('aria-busy')).toBe('false');
      expect(findCells().at(0).text()).toBe('An error occurred while fetching the tokens.');
    });
  });
});
