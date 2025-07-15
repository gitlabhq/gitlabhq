import { GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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
    wrapper = shallowMountExtended(SearchItem, {
      propsData: {
        item,
        searchQuery: 'root',
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findIcon = () => wrapper.findByTestId('icon');
  const findNamespace = () => wrapper.findByTestId('namespace');
  const findNamespaceBullet = () => wrapper.findByTestId('namespace-bullet');

  it.each([mockUser, mockCommand, mockProject, mockIssue])('should render the item', (item) => {
    createComponent(item);

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('item rendering', () => {
    it('should render avatar when avatar_url is provided', () => {
      const item = {
        text: 'Test Item',
        avatar_url: 'https://example.com/avatar.png',
        entity_id: '123',
        entity_name: 'Test Entity',
      };

      createComponent(item);

      expect(findAvatar().props('src')).toBe(item.avatar_url);
      expect(findAvatar().props('entityId')).toBe(item.entity_id);
      expect(findAvatar().props('entityName')).toBe(item.entity_name);
      expect(findAvatar().props('size')).toBe(16);
      expect(findAvatar().attributes('aria-hidden')).toBe('true');
    });

    it('should not render avatar when avatar_url is undefined', () => {
      const item = {
        text: 'Test Item',
      };

      createComponent(item);

      expect(findAvatar().exists()).toBe(false);
    });

    it('should render icon when present', () => {
      const item = {
        icon: 'search-results',
        text: 'Test Item',
      };

      createComponent(item);

      expect(findIcon().props('name')).toBe(item.icon);
    });

    it('should not render icon when not present', () => {
      const item = {
        text: 'Test Item',
      };

      createComponent(item);

      expect(findIcon().exists()).toBe(false);
    });

    it('should render namespace when present', () => {
      const item = {
        text: 'Test Item',
        namespace: 'test-namespace',
      };

      createComponent(item);

      expect(findNamespaceBullet().exists()).toBe(true);
      expect(findNamespace().text()).toBe('test-namespace');
    });

    it('should not render namespace when not present', () => {
      const item = {
        text: 'Test Item',
      };

      createComponent(item);

      expect(findNamespaceBullet().exists()).toBe(false);
      expect(findNamespace().exists()).toBe(false);
    });
  });
});
