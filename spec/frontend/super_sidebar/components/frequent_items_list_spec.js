import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import FrequentItemsList from '~/super_sidebar/components//frequent_items_list.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { cachedFrequentProjects } from '../mock_data';

const title = s__('Navigation|FREQUENT PROJECTS');
const storageKey = 'storageKey';
const maxItems = 5;
const mockItems = JSON.parse(cachedFrequentProjects);
const mostFrequentProject = mockItems[4];

describe('FrequentItemsList component', () => {
  useLocalStorageSpy();

  let wrapper;

  const findListTitle = () => wrapper.findByTestId('list-title');
  const findNavItems = () => wrapper.findAllComponents(NavItem);
  const findEmptyText = () => wrapper.findByTestId('empty-text');

  const createWrapper = () => {
    wrapper = shallowMountExtended(FrequentItemsList, {
      propsData: {
        title,
        storageKey,
        maxItems,
      },
      slots: {
        empty: '<div data-testid="empty-text" />',
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it("renders the list's title", () => {
      expect(findListTitle().text()).toBe(title);
    });

    it('renders the empty text slot', () => {
      expect(findEmptyText().exists()).toBe(true);
    });
  });

  describe('when there are cached frequent items', () => {
    beforeEach(() => {
      window.localStorage.setItem(storageKey, cachedFrequentProjects);
      createWrapper();
    });

    it('attempts to retrieve the projects and groups from the local storage', () => {
      expect(window.localStorage.getItem).toHaveBeenCalledTimes(1);
      expect(window.localStorage.getItem).toHaveBeenCalledWith(storageKey);
    });

    it('renders the maximum amount of items', () => {
      expect(findNavItems().length).toBe(maxItems);
    });

    it('passes the remapped `item` prop to nav items', () => {
      const firstNavItem = findNavItems().at(0);

      expect(firstNavItem.props('item')).toEqual({
        id: mostFrequentProject.id,
        title: mostFrequentProject.name,
        subtitle: mostFrequentProject.namespace.split(' / ')[0],
        avatar: mostFrequentProject.avatarUrl,
        link: mostFrequentProject.webUrl,
      });
    });

    it('does not render the empty text slot', () => {
      expect(findEmptyText().exists()).toBe(false);
    });
  });
});
