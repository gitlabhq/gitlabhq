import { createWrapper } from '@vue/test-utils';
import MembersTabs from '~/members/components/members_tabs.vue';
import { CONTEXT_TYPE, MEMBERS_TAB_TYPES } from '~/members/constants';
import { initMembersApp } from '~/members/index';
import membersStore from '~/members/store';
import { parseDataAttributes } from '~/members/utils';
import { dataAttribute } from './mock_data';

jest.mock('~/members/store');
membersStore.mockImplementation(jest.requireActual('~/members/store').default);

describe('initMembersApp', () => {
  /** @type {HTMLDivElement} */
  let el;
  let vm;
  /** @type {import('@vue/test-utils').Wrapper<MembersTabs>} */
  let wrapper;

  const options = {
    [MEMBERS_TAB_TYPES.user]: {
      tableFields: ['account'],
      tableAttrs: { table: { 'data-testid': 'members-list' } },
      tableSortableFields: ['account'],
      requestFormatter: () => ({}),
      filteredSearchBar: { show: false },
    },
    [MEMBERS_TAB_TYPES.placeholder]: {
      requestFormatter: () => ({}),
    },
  };

  const setup = () => {
    vm = initMembersApp(el, CONTEXT_TYPE.GROUP, options);
    wrapper = createWrapper(vm);
  };

  beforeEach(() => {
    el = document.createElement('div');
    el.dataset.membersData = dataAttribute;

    window.gon = { current_user_id: 123 };
  });

  afterEach(() => {
    el = null;
  });

  it('renders `MembersTabs`', () => {
    setup();

    expect(wrapper.findComponent(MembersTabs).exists()).toBe(true);
  });

  describe('members Vuex store', () => {
    it('inits members store with parsed data', () => {
      const parsedData = parseDataAttributes(el);
      setup();

      expect(membersStore).toHaveBeenCalledWith({
        ...parsedData[MEMBERS_TAB_TYPES.user],
        ...options[MEMBERS_TAB_TYPES.user],
      });
    });

    it('inits placeholders store', () => {
      setup();

      expect(membersStore).toHaveBeenCalledTimes(Object.keys(options).length);
      expect(membersStore).toHaveBeenCalledWith({
        ...options[MEMBERS_TAB_TYPES.placeholder],
      });
    });
  });
});
