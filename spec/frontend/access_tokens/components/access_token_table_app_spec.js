import { GlButton, GlPagination, GlTable } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AccessTokenTableApp from '~/access_tokens/components/access_token_table_app.vue';
import { EVENT_SUCCESS, PAGE_SIZE } from '~/access_tokens/components/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { sprintf } from '~/locale';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';

describe('~/access_tokens/components/access_token_table_app', () => {
  let wrapper;
  let mockAxios;

  const accessTokenType = 'personal access token';
  const accessTokenTypePlural = 'personal access tokens';
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
        initialActiveAccessTokens: defaultActiveAccessTokens,
        noActiveTokensMessage,
        showRole,
        ...props,
      },
    });
  };

  const triggerSuccess = async (activeAccessTokens = defaultActiveAccessTokens) => {
    wrapper.findComponent(DomElementListener).vm.$emit(EVENT_SUCCESS, {
      detail: [{ active_access_tokens: activeAccessTokens, total: activeAccessTokens.length }],
    });
    await nextTick();
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => findTable().findAll('th > div > span');
  const findCells = () => findTable().findAll('td');
  const findPagination = () => wrapper.findComponent(GlPagination);

  beforeEach(() => {
    const headers = {
      'X-Page': 1,
      'X-Per-Page': 20,
      'X-Total': defaultActiveAccessTokens.length,
    };
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet().reply(
      HTTP_STATUS_OK,
      [
        {
          active_access_tokens: defaultActiveAccessTokens,
          total: defaultActiveAccessTokens.length,
        },
      ],
      headers,
    );
  });

  afterEach(() => {
    wrapper?.destroy();
    mockAxios.restore();
  });

  describe.each`
    backendPagination
    ${true}
    ${false}
  `('when backendPagination is $backendPagination', ({ backendPagination }) => {
    it('should render an empty table with a default message', () => {
      createComponent({ initialActiveAccessTokens: [], backendPagination });

      const cells = findCells();
      expect(cells).toHaveLength(1);
      expect(cells.at(0).text()).toBe(
        sprintf('This user has no active %{accessTokenTypePlural}.', { accessTokenTypePlural }),
      );
    });

    it('should render an empty table with a custom message', () => {
      const noTokensMessage = 'This group has no active access tokens.';
      createComponent({
        initialActiveAccessTokens: [],
        noActiveTokensMessage: noTokensMessage,
        backendPagination,
      });

      const cells = findCells();
      expect(cells).toHaveLength(1);
      expect(cells.at(0).text()).toBe(noTokensMessage);
    });

    describe('table headers', () => {
      it('should include `Action` column', () => {
        createComponent({ backendPagination });

        const headers = findHeaders();
        expect(headers.wrappers.map((header) => header.text())).toStrictEqual([
          'Token name',
          'Scopes',
          'Created',
          'Last Used',
          'Expires',
          'Action',
        ]);
      });

      it('should include `Role` column', () => {
        createComponent({ showRole: true, backendPagination });

        const headers = findHeaders();
        expect(headers.wrappers.map((header) => header.text())).toStrictEqual([
          'Token name',
          'Scopes',
          'Created',
          'Last Used',
          'Expires',
          'Role',
          'Action',
        ]);
      });
    });

    it('`Last Used` header should contain a link and an assistive message', () => {
      createComponent({ backendPagination });

      const headers = wrapper.findAll('th');
      const lastUsed = headers.at(3);
      const anchor = lastUsed.find('a');
      const assistiveElement = lastUsed.find('.gl-sr-only');
      expect(anchor.exists()).toBe(true);
      expect(anchor.attributes('href')).toBe(
        '/help/user/profile/personal_access_tokens.md#view-the-last-time-a-token-was-used',
      );
      expect(assistiveElement.text()).toBe('The last time a token was used');
    });

    it('updates the table after new tokens are created', async () => {
      createComponent({ initialActiveAccessTokens: [], showRole: true, backendPagination });
      await triggerSuccess();

      const cells = findCells();
      expect(cells).toHaveLength(14);

      // First row
      expect(cells.at(0).text()).toBe('a');
      expect(cells.at(1).text()).toBe('api');
      expect(cells.at(2).text()).not.toBe('Never');
      expect(cells.at(3).text()).toBe('Never');
      expect(cells.at(4).text()).toBe('Never');
      expect(cells.at(5).text()).toBe('Maintainer');
      let button = cells.at(6).findComponent(GlButton);
      expect(button.attributes()).toMatchObject({
        'aria-label': 'Revoke',
        'data-testid': 'revoke-button',
        href: '/-/user_settings/personal_access_tokens/1/revoke',
        'data-confirm': sprintf(
          'Are you sure you want to revoke the %{accessTokenType} "%{tokenName}"? This action cannot be undone.',

          { accessTokenType, tokenName: 'a' },
        ),
      });
      expect(button.props('category')).toBe('tertiary');

      // Second row
      expect(cells.at(7).text()).toBe('b');
      expect(cells.at(8).text()).toBe('api, sudo');
      expect(cells.at(9).text()).not.toBe('Never');
      expect(cells.at(10).text()).not.toBe('Never');
      expect(cells.at(11).text()).toBe('Expired');
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
            backendPagination,
          });

          const headers = findHeaders();
          expect(headers).toHaveLength(6);
          ['Token name', 'Scopes', 'Created', 'Last Used', 'Expires', 'Role'].forEach(
            (text, index) => {
              expect(headers.at(index).text()).toBe(text);
            },
          );
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
            backendPagination,
          });

          expect(findHeaders().at(6).text()).toBe('Action');
          expect(findCells().at(6).findComponent(GlButton).exists()).toBe(false);
        },
      );
    });
  });

  describe('when backendPagination is false', () => {
    it('sorts rows alphabetically', async () => {
      createComponent({ showRole: true, backendPagination: false });

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
      createComponent({ showRole: true, backendPagination: false });

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
          backendPagination: false,
        });

        expect(findPagination().exists()).toBe(false);
      });

      describe('when number of tokens exceeds the first page', () => {
        beforeEach(() => {
          createComponent({
            initialActiveAccessTokens: Array(PAGE_SIZE + 1).fill(defaultActiveAccessTokens[0]),
            backendPagination: false,
          });
        });

        it('shows the pagination component', () => {
          expect(findPagination().exists()).toBe(true);
        });

        describe('when clicked on the second page', () => {
          it('shows only one token in the table', async () => {
            expect(findCells()).toHaveLength(PAGE_SIZE * 6);
            await findPagination().vm.$emit('input', 2);
            await nextTick();

            expect(findCells()).toHaveLength(6);
          });

          it('scrolls to the top', async () => {
            const scrollToSpy = jest.spyOn(window, 'scrollTo');
            await findPagination().vm.$emit('input', 2);
            await nextTick();

            expect(scrollToSpy).toHaveBeenCalledWith({ top: 0 });
          });
        });
      });
    });
  });

  describe('when backendPagination is true', () => {
    beforeEach(() => {
      createComponent({ showRole: true, backendPagination: true });
    });

    it('does not sort rows alphabetically', async () => {
      // await axios.waitForAll();
      const cells = findCells();

      // First and second rows
      expect(cells.at(0).text()).toBe('a');
      expect(cells.at(7).text()).toBe('b');

      const headers = findHeaders();
      await headers.at(0).trigger('click');
      await headers.at(0).trigger('click');

      // First and second rows are not swapped
      expect(cells.at(0).text()).toBe('a');
      expect(cells.at(7).text()).toBe('b');
    });

    it('change the busy state in the table', async () => {
      expect(findTable().attributes('aria-busy')).toBe('true');

      await axios.waitForAll();

      expect(findTable().attributes('aria-busy')).toBe('false');
    });

    describe('when a new token is created', () => {
      it('replaces the window history', async () => {
        const replaceStateSpy = jest.spyOn(window.history, 'replaceState');
        await triggerSuccess();

        expect(replaceStateSpy).toHaveBeenCalledWith(null, '', '?page=1');
      });
    });

    describe('pagination', () => {
      it('does not show pagination component', async () => {
        await axios.waitForAll();

        expect(findPagination().exists()).toBe(false);
      });

      describe('when number of tokens exceeds the first page', () => {
        beforeEach(() => {
          const accessTokens = Array(21).fill(defaultActiveAccessTokens[0]);

          const headers = {
            'X-Page': 1,
            'X-Per-Page': 20,
            'X-Total': accessTokens.length,
          };
          mockAxios.onGet().reply(
            HTTP_STATUS_OK,
            [
              {
                active_access_tokens: accessTokens,
                total: accessTokens.length,
              },
            ],
            headers,
          );
          createComponent({ initialActiveAccessTokens: accessTokens, backendPagination: true });
        });

        it('shows the pagination component', async () => {
          await axios.waitForAll();

          expect(findPagination().exists()).toBe(true);
        });

        describe('when clicked on the second page', () => {
          it('replace the window history', async () => {
            await axios.waitForAll();

            const replaceStateSpy = jest.spyOn(window.history, 'replaceState');
            await findPagination().vm.$emit('input', 2);
            await axios.waitForAll();

            expect(replaceStateSpy).toHaveBeenCalledWith(null, '', '?page=2');
          });

          it('scrolls to the top', async () => {
            await axios.waitForAll();

            const scrollToSpy = jest.spyOn(window, 'scrollTo');
            await findPagination().vm.$emit('input', 2);
            await axios.waitForAll();

            expect(scrollToSpy).toHaveBeenCalledWith({ top: 0 });
          });
        });
      });
    });
  });
});
