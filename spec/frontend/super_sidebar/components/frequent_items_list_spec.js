import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import FrequentItemsList from '~/super_sidebar/components//frequent_items_list.vue';
import ItemsList from '~/super_sidebar/components/items_list.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { cachedFrequentProjects } from '../mock_data';

const title = s__('Navigation|FREQUENT PROJECTS');
const pristineText = s__('Navigation|Projects you visit often will appear here.');
const storageKey = 'storageKey';
const maxItems = 5;

describe('FrequentItemsList component', () => {
  useLocalStorageSpy();

  let wrapper;

  const findListTitle = () => wrapper.findByTestId('list-title');
  const findListEditButton = () => findListTitle().findComponent(GlButton);
  const findItemsList = () => wrapper.findComponent(ItemsList);
  const findEmptyText = () => wrapper.findByTestId('empty-text');

  const createWrapper = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(FrequentItemsList, {
      propsData: {
        title,
        pristineText,
        storageKey,
        maxItems,
        ...props,
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

    it('renders the empty text', () => {
      expect(findEmptyText().exists()).toBe(true);
      expect(findEmptyText().text()).toBe(pristineText);
    });
  });

  describe('when there are cached frequent items', () => {
    beforeEach(() => {
      window.localStorage.setItem(storageKey, cachedFrequentProjects);
      createWrapper();
    });

    it('attempts to retrieve the items from the local storage', () => {
      expect(window.localStorage.getItem).toHaveBeenCalledTimes(1);
      expect(window.localStorage.getItem).toHaveBeenCalledWith(storageKey);
    });

    it('renders the maximum amount of items', () => {
      expect(findItemsList().props('items').length).toBe(maxItems);
    });

    it('does not render the empty text slot', () => {
      expect(findEmptyText().exists()).toBe(false);
    });

    describe('items editing', () => {
      it('renders edit button within header', () => {
        const itemsEditButton = findListEditButton();

        expect(itemsEditButton.exists()).toBe(true);
        expect(itemsEditButton.attributes('title')).toBe('Toggle edit mode');
        expect(itemsEditButton.findComponent(GlIcon).props('name')).toBe('pencil');
      });

      it('clicking edit button makes items list editable', async () => {
        // Off by default
        expect(findItemsList().props('editable')).toBe(false);

        // On when clicked
        await findListEditButton().vm.$emit('click');
        expect(findItemsList().props('editable')).toBe(true);

        // Off when clicked again
        await findListEditButton().vm.$emit('click');
        expect(findItemsList().props('editable')).toBe(false);
      });

      it('remove-item event emission from items-list causes list item to be removed', async () => {
        const localStorageProjects = findItemsList().props('items');
        await findListEditButton().vm.$emit('click');

        await findItemsList().vm.$emit('remove-item', localStorageProjects[0]);

        expect(findItemsList().props('items')).toHaveLength(maxItems - 1);
        expect(findItemsList().props('items')).not.toContain(localStorageProjects[0]);
      });
    });
  });
});
