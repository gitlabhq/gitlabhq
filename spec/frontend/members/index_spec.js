import { createWrapper } from '@vue/test-utils';
import MembersTabs from '~/members/components/members_tabs.vue';
import { MEMBER_TYPES } from '~/members/constants';
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
    [MEMBER_TYPES.user]: {
      tableFields: ['account'],
      tableAttrs: { table: { 'data-testid': 'members-list' } },
      tableSortableFields: ['account'],
      requestFormatter: () => ({}),
      filteredSearchBar: { show: false },
    },
  };

  const setup = () => {
    vm = initMembersApp(el, options);
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
        ...parsedData[MEMBER_TYPES.user],
        ...options[MEMBER_TYPES.user],
      });
    });
  });
});
