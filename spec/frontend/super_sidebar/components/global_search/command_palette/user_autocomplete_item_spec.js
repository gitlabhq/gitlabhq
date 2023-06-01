import { shallowMount } from '@vue/test-utils';
import UserAutocompleteItem from '~/super_sidebar/components/global_search/command_palette/user_autocomplete_item.vue';
import { userMapper } from '~/super_sidebar/components/global_search/command_palette/utils';
import { USERS } from './mock_data';

describe('UserAutocompleteItem', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(UserAutocompleteItem, {
      propsData: {
        user: USERS.map(userMapper)[0],
        searchQuery: 'root',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should render user item', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
