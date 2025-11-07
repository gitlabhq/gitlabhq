import { GlTable, GlLoadingIcon, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TokensTable from '~/vue_shared/access_tokens/components/personal_access_tokens/tokens_table.vue';
import { stubComponent } from 'helpers/stub_component';
import DateWithTooltip from '~/vue_shared/access_tokens/components/personal_access_tokens/date_with_tooltip.vue';

const ACTIVE_TOKEN = {
  name: 'Active',
  active: true,
  revoked: false,
  description: 'Active description',
  expiresAt: '2010-10-10',
  lastUsedAt: null,
};

const EXPIRING_TOKEN = {
  name: 'Expiring',
  active: true,
  revoked: false,
  description: 'Expiring token',
  expiresAt: '2024-07-14',
  lastUsedAt: '2015-05-12T15:42:28.152Z',
};

const EXPIRED_TOKEN = {
  name: 'Expired',
  active: false,
  revoked: false,
  description: 'Expired token',
  expiresAt: '2023-02-01',
  lastUsedAt: null,
};

const REVOKED_TOKEN = {
  name: 'Revoked',
  active: false,
  revoked: true,
  description: 'Revoked token',
  expiresAt: '2025-11-23',
  lastUsedAt: '2015-03-21T22:16:34.513Z',
};

const TOKENS = [ACTIVE_TOKEN, EXPIRING_TOKEN, EXPIRED_TOKEN, REVOKED_TOKEN];
const tableStub = stubComponent(GlTable, {
  props: ['items', 'busy', 'stacked', 'showEmpty', 'emptyText'],
});

describe('Personal access tokens table component', () => {
  let wrapper;

  const createWrapper = ({ loading = false, tableComponent = GlTable } = {}) => {
    wrapper = mountExtended(TokensTable, {
      propsData: { tokens: TOKENS, loading },
      stubs: {
        GlTable: tableComponent,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaderCells = () => wrapper.findAll('thead th');
  const findRows = () => wrapper.findAll('tbody tr');
  const findCell = ({ row, column }) => findRows().at(row).findAll('td').at(column);
  const findExpiration = (row) =>
    findCell({ row, column: 2 }).findAllComponents(DateWithTooltip).at(0);
  const findLastUsed = (row) =>
    findCell({ row, column: 2 }).findAllComponents(DateWithTooltip).at(1);
  const findActionDropdown = (row) =>
    findCell({ row, column: 3 }).findComponent(GlDisclosureDropdown);
  const findActionDropdownItems = (row) =>
    findActionDropdown(row).findAllComponents(GlDisclosureDropdownItem);

  it('shows table', () => {
    createWrapper({ tableComponent: tableStub });

    expect(findTable().props()).toHaveProperty('showEmpty');
    expect(findTable().props()).toMatchObject({
      items: TOKENS,
      busy: false,
      stacked: 'sm',
      emptyText: 'No access tokens',
    });
  });

  describe('when data is loading', () => {
    it('shows table as busy', () => {
      createWrapper({ loading: true, tableComponent: tableStub });

      expect(findTable().props('busy')).toBe(true);
    });

    it('shows loading icon', () => {
      createWrapper({ loading: true });

      expect(findTable().findComponent(GlLoadingIcon).props('size')).toBe('md');
    });
  });

  describe('table structure', () => {
    const headers = ['Name', 'Description', 'Status', 'Actions'];

    beforeEach(() => createWrapper());

    it('shows 4 columns', () => {
      expect(findHeaderCells()).toHaveLength(4);
    });

    it('shows 4 rows', () => {
      expect(findRows()).toHaveLength(4);
    });

    it.each(headers)('shows %s header', (name) => {
      expect(findHeaderCells().at(headers.indexOf(name)).text()).toBe(name);
    });
  });

  describe.each`
    token             | expiresText                | lastUsedText
    ${ACTIVE_TOKEN}   | ${'Expires: Oct 10, 2010'} | ${'Never'}
    ${EXPIRING_TOKEN} | ${'Expires: Jul 14, 2024'} | ${'Last used: May 12, 2015'}
  `('for $token.name token', ({ token, expiresText, lastUsedText }) => {
    const row = TOKENS.indexOf(token);

    beforeEach(() => createWrapper());

    it('shows token name', () => {
      expect(findCell({ row, column: 0 }).text()).toBe(token.name);
    });

    it('shows token description', () => {
      expect(findCell({ row, column: 1 }).text()).toBe(token.description);
    });

    describe('token expiration', () => {
      it('shows date with tooltip', () => {
        expect(findExpiration(row).props()).toEqual({
          timestamp: token.expiresAt,
          icon: 'expire',
          token,
        });
      });

      it('shows text', () => {
        expect(findExpiration(row).text()).toContain(expiresText);
      });
    });

    describe('token last used', () => {
      it('shows date with tooltip', () => {
        expect(findLastUsed(row).props()).toEqual({
          timestamp: token.lastUsedAt,
          icon: 'hourglass',
          token: null,
        });
      });

      it('shows text', () => {
        expect(findLastUsed(row).text()).toContain(lastUsedText);
      });
    });

    describe('actions dropdown', () => {
      it('shows dropdown', () => {
        expect(findActionDropdown(row).props()).toMatchObject({
          category: 'tertiary',
          icon: 'ellipsis_v',
          noCaret: true,
        });
      });

      it('shows 3 dropdown items', () => {
        expect(findActionDropdownItems(row)).toHaveLength(3);
      });

      describe.each`
        index | text              | variant      | eventName
        ${0}  | ${'View details'} | ${undefined} | ${'select'}
        ${1}  | ${'Rotate'}       | ${undefined} | ${'rotate'}
        ${2}  | ${'Revoke'}       | ${'danger'}  | ${'revoke'}
      `('for $text option', ({ index, text, variant, eventName }) => {
        const findOption = () => findActionDropdownItems(row).at(index);

        it('shows text', () => {
          expect(findOption().text()).toBe(text);
        });

        it('has expected variant', () => {
          expect(findOption().props('item').variant).toBe(variant);
        });

        it(`emits ${eventName} event when clicked`, () => {
          findOption().props('item').action();

          expect(wrapper.emitted(eventName)).toHaveLength(1);
          expect(wrapper.emitted(eventName)[0][0]).toBe(TOKENS[row]);
        });
      });
    });
  });

  it.each([EXPIRED_TOKEN, REVOKED_TOKEN])(
    'does not show action dropdown for $name token',
    (token) => {
      const row = TOKENS.indexOf(token);
      createWrapper();

      expect(findActionDropdown(row).exists()).toBe(false);
    },
  );
});
