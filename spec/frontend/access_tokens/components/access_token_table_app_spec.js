import { GlButton, GlModal, GlPagination, GlTable } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AccessTokenTableApp from '~/access_tokens/components/access_token_table_app.vue';
import { EVENT_SUCCESS, PAGE_SIZE } from '~/access_tokens/components/constants';
import { createAlert, VARIANT_DANGER } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { sprintf } from '~/locale';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';

jest.mock('~/alert');

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
      description: 'Test description',
      scopes: ['api'],
      created_at: '2021-05-01T00:00:00.000Z',
      last_used_at: null,
      last_used_ips: null,
      expired: false,
      expires_soon: true,
      expires_at: null,
      revoked: false,
      revoke_path: '/-/user_settings/personal_access_tokens/1/revoke',
      rotate_path: '/-/user_settings/personal_access_tokens/1/rotate',
      role: 'Maintainer',
    },
    {
      name: 'b',
      description: 'Test description',
      scopes: ['api', 'sudo'],
      created_at: '2022-04-21T00:00:00.000Z',
      last_used_at: '2022-04-21T00:00:00.000Z',
      last_used_ips: ['192.168.0.1', '192.168.0.2'],
      expired: true,
      expires_soon: false,
      expires_at: new Date().toISOString(),
      revoked: false,
      revoke_path: '/-/user_settings/personal_access_tokens/2/revoke',
      rotate_path: '/-/user_settings/personal_access_tokens/2/rotate',
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
        glFeatures: {
          patIp: true,
        },
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

  const triggerTokenRotation = async () => {
    await wrapper.findAllComponents(GlButton).at(1).trigger('click');
    await wrapper.findComponent(GlModal).vm.$emit('primary');
    await axios.waitForAll();
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => findTable().findAll('thead th > div > span');
  const findCells = () => findTable().findAll('tbody td, tbody th');
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
    createAlert.mockClear();
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
          'Description',
          'Scopes',
          'Created',
          'Last Used',
          'Last Used IPs',
          'Expires',
          'Action',
        ]);
      });

      it('should include `Role` column', () => {
        createComponent({ showRole: true, backendPagination });

        const headers = findHeaders();
        expect(headers.wrappers.map((header) => header.text())).toStrictEqual([
          'Token name',
          'Description',
          'Scopes',
          'Created',
          'Last Used',
          'Last Used IPs',
          'Expires',
          'Role',
          'Action',
        ]);
      });
    });

    it('`Last Used` header should contain a link and an assistive message', () => {
      createComponent({ backendPagination });

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

    it('`Last Used IPs` header should contain a link and an assistive message', () => {
      createComponent({ backendPagination });

      const headers = wrapper.findAll('th');
      const lastUsedIPs = headers.at(5);
      const anchor = lastUsedIPs.find('a');
      const assistiveElement = lastUsedIPs.find('.gl-sr-only');
      expect(anchor.exists()).toBe(true);
      expect(anchor.attributes('href')).toBe(
        '/help/user/profile/personal_access_tokens.md#view-the-time-at-and-ips-where-a-token-was-last-used',
      );
      expect(assistiveElement.text()).toBe(
        'The last five distinct IP addresses from where the token was used',
      );
    });

    it('updates the table after new tokens are created', async () => {
      createComponent({ initialActiveAccessTokens: [], showRole: true, backendPagination });
      await triggerSuccess();

      const cells = findCells();
      expect(cells).toHaveLength(18);

      // First row
      expect(cells.at(0).text()).toBe('a');
      expect(cells.at(1).text()).toBe('Test description');
      expect(cells.at(2).text()).toBe('api');
      expect(cells.at(3).text()).not.toBe('Never');
      expect(cells.at(4).text()).toBe('Never');
      expect(cells.at(5).text()).toBe('-');
      expect(cells.at(6).text()).toBe('Never');
      expect(cells.at(7).text()).toBe('Maintainer');
      let buttons = cells.at(8).findAllComponents(GlButton);
      expect(buttons).toHaveLength(2);
      expect(buttons.at(0).attributes()).toMatchObject({
        'aria-label': 'Revoke',
        'data-testid': 'revoke-button',
        href: '/-/user_settings/personal_access_tokens/1/revoke',
        'data-confirm': sprintf(
          'Are you sure you want to revoke the %{accessTokenType} "%{tokenName}"? This action cannot be undone. Any tools that rely on this access token will stop working.',
          { accessTokenType, tokenName: 'a' },
        ),
      });
      expect(buttons.at(0).props('category')).toBe('tertiary');
      expect(buttons.at(1).attributes()).toMatchObject({
        'aria-label': 'Rotate',
        'data-testid': 'rotate-button',
      });
      expect(buttons.at(1).props('category')).toBe('tertiary');

      // Second row
      expect(cells.at(9).text()).toBe('b');
      expect(cells.at(10).text()).toBe('Test description');
      expect(cells.at(11).text()).toBe('api, sudo');
      expect(cells.at(12).text()).not.toBe('Never');
      expect(cells.at(13).text()).not.toBe('Never');
      expect(cells.at(14).text()).toBe('192.168.0.1, 192.168.0.2');
      expect(cells.at(15).text()).toBe('Expired');
      expect(cells.at(16).text()).toBe('Maintainer');
      buttons = cells.at(17).findAllComponents(GlButton);
      expect(buttons.at(0).attributes('href')).toBe(
        '/-/user_settings/personal_access_tokens/2/revoke',
      );
      expect(buttons.at(0).props('category')).toBe('tertiary');
      expect(buttons.at(1).props('category')).toBe('tertiary');
    });

    it('updates the table after a token is rotated', async () => {
      const rotatePath = '/-/user_settings/personal_access_tokens/1/rotate';
      mockAxios.onPut(rotatePath).reply(HTTP_STATUS_OK, {
        new_token: 'new_token',
        active_access_tokens: defaultActiveAccessTokens,
        total: 1,
      });
      createComponent({ backendPagination });

      await triggerTokenRotation();

      expect(mockAxios.history.put).toHaveLength(1);
      expect(mockAxios.history.put[0]).toMatchObject({
        url: rotatePath,
      });
      const cells = findCells();
      expect(cells).toHaveLength(16);
      expect(cells.at(0).text()).toBe('a');
      expect(cells.at(8).text()).toBe('b');
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('shows error if token fails to be rotated', async () => {
      const revokePath = '/-/user_settings/personal_access_tokens/1/rotate';
      mockAxios.onPut(revokePath).reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, {
        active_access_tokens: defaultActiveAccessTokens,
        total: defaultActiveAccessTokens.length,
        message: 'Token already revoked',
      });
      createComponent({ backendPagination });

      await triggerTokenRotation();

      expect(mockAxios.history.put).toHaveLength(1);
      expect(mockAxios.history.put[0]).toMatchObject({
        url: revokePath,
      });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Token already revoked',
        variant: VARIANT_DANGER,
      });
    });

    describe('when revoke_path and rotate_path are', () => {
      describe('absent in all tokens', () => {
        it('should not include `Action` column', () => {
          createComponent({
            initialActiveAccessTokens: defaultActiveAccessTokens.map(
              ({ revoke_path, rotate_path, ...rest }) => rest,
            ),
            showRole: true,
            backendPagination,
          });

          const headers = findHeaders();
          expect(headers).toHaveLength(8);
          [
            'Token name',
            'Description',
            'Scopes',
            'Created',
            'Last Used',
            'Last Used IPs',
            'Expires',
            'Role',
          ].forEach((text, index) => {
            expect(headers.at(index).text()).toBe(text);
          });
        });
      });

      it.each([
        { revoke_path: null, rotate_path: null },
        { revoke_path: undefined, rotate_path: undefined },
      ])('%p in some tokens, does not show revoke and rotate buttons', (input) => {
        createComponent({
          initialActiveAccessTokens: [
            defaultActiveAccessTokens.map((data) => ({ ...data, ...input }))[0],
            defaultActiveAccessTokens[1],
          ],
          showRole: true,
          backendPagination,
        });

        expect(findHeaders().at(8).text()).toBe('Action');
        expect(findCells().at(8).findComponent(GlButton).exists()).toBe(false);
      });

      it.each([
        { revoke_path: '/-/user_settings/personal_access_tokens/1/revoke', rotate_path: null },
        { revoke_path: null, rotate_path: '/-/user_settings/personal_access_tokens/1/rotate' },
      ])(`% in some tokens, shows revoke or rotate button`, (input) => {
        createComponent({
          initialActiveAccessTokens: [
            defaultActiveAccessTokens.map((data) => ({ ...data, ...input }))[0],
            defaultActiveAccessTokens[1],
          ],
          showRole: true,
          backendPagination,
        });

        expect(findHeaders().at(8).text()).toBe('Action');
        expect(findCells().at(8).findComponent(GlButton).exists()).toBe(true);
      });
    });
  });

  describe('when backendPagination is false', () => {
    it('sorts rows alphabetically', async () => {
      createComponent({ showRole: true, backendPagination: false });

      const cells = findCells();

      // First and second rows
      expect(cells.at(0).text()).toBe('a');
      expect(cells.at(9).text()).toBe('b');

      const headers = findHeaders();
      await headers.at(0).trigger('click');
      await headers.at(0).trigger('click');

      // First and second rows have swapped
      expect(cells.at(0).text()).toBe('b');
      expect(cells.at(9).text()).toBe('a');
    });

    it('sorts rows by date', async () => {
      createComponent({ showRole: true, backendPagination: false });

      const cells = findCells();

      // First and second rows
      expect(cells.at(4).text()).toBe('Never');
      expect(cells.at(13).text()).not.toBe('Never');

      const headers = findHeaders();
      await headers.at(4).trigger('click');

      // First and second rows have swapped
      expect(cells.at(4).text()).not.toBe('Never');
      expect(cells.at(13).text()).toBe('Never');
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
            expect(findCells()).toHaveLength(PAGE_SIZE * 8);
            await findPagination().vm.$emit('input', 2);
            await nextTick();

            expect(findCells()).toHaveLength(8);
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
      const cells = findCells();

      // First and second rows
      expect(cells.at(0).text()).toBe('a');
      expect(cells.at(9).text()).toBe('b');

      const headers = findHeaders();
      await headers.at(0).trigger('click');
      await headers.at(0).trigger('click');

      // First and second rows are not swapped
      expect(cells.at(0).text()).toBe('a');
      expect(cells.at(9).text()).toBe('b');
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
