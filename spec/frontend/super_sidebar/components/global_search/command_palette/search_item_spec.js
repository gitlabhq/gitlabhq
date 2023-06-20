import { shallowMount } from '@vue/test-utils';
import SearchItem from '~/super_sidebar/components/global_search/command_palette/search_item.vue';
import { getFormattedItem } from '~/super_sidebar/components/global_search/utils';
import { linksReducer } from '~/super_sidebar/components/global_search/command_palette/utils';
import { USERS, LINKS, PROJECT, ISSUE } from './mock_data';

jest.mock('~/lib/utils/highlight', () => ({
  __esModule: true,
  default: (text) => text,
}));
const mockUser = getFormattedItem(USERS[0]);
const mockCommand = LINKS.reduce(linksReducer, [])[1];
const mockProject = getFormattedItem(PROJECT);
const mockIssue = getFormattedItem(ISSUE);

describe('SearchItem', () => {
  let wrapper;

  const createComponent = (item) => {
    wrapper = shallowMount(SearchItem, {
      propsData: {
        item,
        searchQuery: 'root',
      },
    });
  };

  it.each([mockUser, mockCommand, mockProject, mockIssue])('should render the item', (item) => {
    createComponent(item);

    expect(wrapper.element).toMatchSnapshot();
  });
});
