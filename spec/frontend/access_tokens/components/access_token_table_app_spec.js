import { GlButton, GlPagination, GlTable } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AccessTokenTableApp from '~/access_tokens/components/access_token_table_app.vue';
import { EVENT_SUCCESS, PAGE_SIZE } from '~/access_tokens/components/constants';
import { __, s__, sprintf } from '~/locale';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';

describe('~/access_tokens/components/access_token_table_app', () => {
  let wrapper;

  const accessTokenType = 'personal access token';
  const accessTokenTypePlural = 'personal access tokens';
  const information = undefined;
  const noActiveTokensMessage = 'This user has no active personal access tokens.';
  const showRole = false;

  const defaultActiveAccessTokens = [
    {
      name: 'a',
      scopes: ['api'],
      created_at: '2021-05-01T00:00:00.000Z',
      last_used_at: null,
      expired: false,
      expires_soon: true,
      expires_at: null,
      revoked: false,
      revoke_path: '/-/user_settings/personal_access_tokens/1/revoke',
      role: 'Maintainer',
    },
    {
      name: 'b',
      scopes: ['api', 'sudo'],
      created_at: '2022-04-21T00:00:00.000Z',
      last_used_at: '2022-04-21T00:00:00.000Z',
      expired: true,
      expires_soon: false,
      expires_at: new Date().toISOString(),
      revoked: false,
      revoke_path: '/-/user_settings/personal_access_tokens/2/revoke',
      role: 'Maintainer',
    },
  ];

  const createComponent = (props = {}) => {
    wrapper = mountExtended(AccessTokenTableApp, {
      provide: {
        accessTokenType,
        accessTokenTypePlural,
        information,
        initialActiveAccessTokens: defaultActiveAccessTokens,
        noActiveTokensMessage,
        showRole,
        ...props,
      },
    });
  };

  const triggerSuccess = async (activeAccessTokens = defaultActiveAccessTokens) => {
    wrapper
      .findComponent(DomElementListener)
      .vm.$emit(EVENT_SUCCESS, { detail: [{ active_access_tokens: activeAccessTokens }] });
    await nextTick();
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => findTable().findAll('th > div > span');
  const findCells = () => findTable().findAll('td');
  const findPagination = () => wrapper.findComponent(GlPagination);

  afterEach(() => {
    wrapper?.destroy();
  });

  it('should render an empty table with a default message', () => {
    createComponent({ initialActiveAccessTokens: [] });

    const cells = findCells();
    expect(cells).toHaveLength(1);
    expect(cells.at(0).text()).toBe(
      sprintf(__('This user has no active %{accessTokenTypePlural}.'), { accessTokenTypePlural }),
    );
  });

  it('should render an empty table with a custom message', () => {
    const noTokensMessage = 'This group has no active access tokens.';
    createComponent({ initialActiveAccessTokens: [], noActiveTokensMessage: noTokensMessage });

    const cells = findCells();
    expect(cells).toHaveLength(1);
    expect(cells.at(0).text()).toBe(noTokensMessage);
  });

  describe('table headers', () => {
    it('should include `Action` column', () => {
      createComponent();

      const headers = findHeaders();
      expect(headers.wrappers.map((header) => header.text())).toStrictEqual([
        __('Token name'),
        __('Scopes'),
        s__('AccessTokens|Created'),
        'Last Used',
        __('Expires'),
        __('Action'),
      ]);
    });

    it('should include `Role` column', () => {
      createComponent({ showRole: true });

      const headers = findHeaders();
      expect(headers.wrappers.map((header) => header.text())).toStrictEqual([
        __('Token name'),
        __('Scopes'),
        s__('AccessTokens|Created'),
        'Last Used',
        __('Expires'),
        __('Role'),
        __('Action'),
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

  it('updates the table after new tokens are created', async () => {
    createComponent({ initialActiveAccessTokens: [], showRole: true });
    await triggerSuccess();

    const cells = findCells();
    expect(cells).toHaveLength(14);

    // First row
    expect(cells.at(0).text()).toBe('a');
    expect(cells.at(1).text()).toBe('api');
    expect(cells.at(2).text()).not.toBe(__('Never'));
    expect(cells.at(3).text()).toBe(__('Never'));
    expect(cells.at(4).text()).toBe(__('Never'));
    expect(cells.at(5).text()).toBe('Maintainer');
    let button = cells.at(6).findComponent(GlButton);
    expect(button.attributes()).toMatchObject({
      'aria-label': __('Revoke'),
      'data-testid': 'revoke-button',
      href: '/-/user_settings/personal_access_tokens/1/revoke',
      'data-confirm': sprintf(
        __(
          'Are you sure you want to revoke the %{accessTokenType} "%{tokenName}"? This action cannot be undone.',
        ),
        { accessTokenType, tokenName: 'a' },
      ),
    });
    expect(button.props('category')).toBe('tertiary');

    // Second row
    expect(cells.at(7).text()).toBe('b');
    expect(cells.at(8).text()).toBe('api, sudo');
    expect(cells.at(9).text()).not.toBe(__('Never'));
    expect(cells.at(10).text()).not.toBe(__('Never'));
    expect(cells.at(11).text()).toBe(__('Expired'));
    expect(cells.at(12).text()).toBe('Maintainer');
    button = cells.at(13).findComponent(GlButton);
    expect(button.attributes('href')).toBe('/-/user_settings/personal_access_tokens/2/revoke');
    expect(button.props('category')).toBe('tertiary');
  });

  describe('when revoke_path is', () => {
    describe('absent in all tokens', () => {
      it('should not include `Action` column', () => {
        createComponent({
          initialActiveAccessTokens: defaultActiveAccessTokens.map(
            ({ revoke_path, ...rest }) => rest,
          ),
          showRole: true,
        });

        const headers = findHeaders();
        expect(headers).toHaveLength(6);
        [
          __('Token name'),
          __('Scopes'),
          s__('AccessTokens|Created'),
          'Last Used',
          __('Expires'),
          __('Role'),
        ].forEach((text, index) => {
          expect(headers.at(index).text()).toBe(text);
        });
      });
    });

    it.each([{ revoke_path: null }, { revoke_path: undefined }])(
      '%p in some tokens, does not show revoke button',
      (input) => {
        createComponent({
          initialActiveAccessTokens: [
            defaultActiveAccessTokens.map((data) => ({ ...data, ...input }))[0],
            defaultActiveAccessTokens[1],
          ],
          showRole: true,
        });

        expect(findHeaders().at(6).text()).toBe(__('Action'));
        expect(findCells().at(6).findComponent(GlButton).exists()).toBe(false);
      },
    );
  });

  it('sorts rows alphabetically', async () => {
    createComponent({ showRole: true });

    const cells = findCells();

    // First and second rows
    expect(cells.at(0).text()).toBe('a');
    expect(cells.at(7).text()).toBe('b');

    const headers = findHeaders();
    await headers.at(0).trigger('click');
    await headers.at(0).trigger('click');

    // First and second rows have swapped
    expect(cells.at(0).text()).toBe('b');
    expect(cells.at(7).text()).toBe('a');
  });

  it('sorts rows by date', async () => {
    createComponent({ showRole: true });

    const cells = findCells();

    // First and second rows
    expect(cells.at(3).text()).toBe('Never');
    expect(cells.at(10).text()).not.toBe('Never');

    const headers = findHeaders();
    await headers.at(3).trigger('click');

    // First and second rows have swapped
    expect(cells.at(3).text()).not.toBe('Never');
    expect(cells.at(10).text()).toBe('Never');
  });

  describe('pagination', () => {
    it('does not show pagination component', () => {
      createComponent({
        initialActiveAccessTokens: Array(PAGE_SIZE).fill(defaultActiveAccessTokens[0]),
      });

      expect(findPagination().exists()).toBe(false);
    });

    it('shows the pagination component', () => {
      createComponent({
        initialActiveAccessTokens: Array(PAGE_SIZE + 1).fill(defaultActiveAccessTokens[0]),
      });
      expect(findPagination().exists()).toBe(true);
    });
  });
});
