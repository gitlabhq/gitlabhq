import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import searchUsersQuery from '~/graphql_shared/queries/users_search_all.query.graphql';

import createMockApollo from 'helpers/mock_apollo_helper';
import UserSelect from '~/pages/import/fogbugz/new_user_map/components/user_select.vue';

Vue.use(VueApollo);

const USERS_RESPONSE = {
  data: {
    users: {
      nodes: [
        {
          id: 'gid://gitlab/User/44',
          avatarUrl: '/avatar1',
          webUrl: '/reported_user_22',
          webPath: '/reported_user_22',
          name: 'Birgit Steuber',
          username: 'reported_user_22',
          __typename: 'UserCore',
        },
        {
          id: 'gid://gitlab/User/43',
          avatarUrl: '/avatar2',
          webUrl: '/reported_user_21',
          webPath: '/reported_user_21',
          name: 'Luke Spinka',
          username: 'reported_user_21',
          __typename: 'UserCore',
        },
      ],
      __typename: 'UserCoreConnection',
    },
  },
};

describe('fogbugz user select component', () => {
  let wrapper;
  const searchQueryHandlerSuccess = jest.fn().mockResolvedValue(USERS_RESPONSE);

  const createComponent = (propsData = { name: 'demo' }) => {
    const fakeApollo = createMockApollo([[searchUsersQuery, searchQueryHandlerSuccess]]);

    wrapper = shallowMount(UserSelect, {
      apolloProvider: fakeApollo,
      propsData,
    });
  };

  it('renders hidden input with name from props', () => {
    const name = 'test';
    createComponent({ name });
    expect(wrapper.find('input').attributes('name')).toBe(name);
  });

  it('syncs input value with value emitted from listbox', async () => {
    createComponent();

    const id = 8;

    wrapper.findComponent(GlCollapsibleListbox).vm.$emit('select', `gid://gitlab/User/${id}`);
    await nextTick();

    expect(wrapper.get('input').attributes('value')).toBe(id.toString());
  });

  it('filters users when search is performed in listbox', async () => {
    createComponent();
    jest.runOnlyPendingTimers();

    wrapper.findComponent(GlCollapsibleListbox).vm.$emit('search', 'test');
    await nextTick();
    jest.runOnlyPendingTimers();

    expect(searchQueryHandlerSuccess).toHaveBeenCalledWith({
      first: expect.anything(),
      search: 'test',
    });
  });
});
