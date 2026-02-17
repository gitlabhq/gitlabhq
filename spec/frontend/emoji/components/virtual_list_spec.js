import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import VirtualList from '~/emoji/components/virtual_list.vue';
import Category from '~/emoji/components/category.vue';

let wrapper;

const defaultCategories = {
  activity: {
    height: 100,
    top: 0,
    emojis: [['👍'], ['👎']],
  },
  people: {
    height: 150,
    top: 100,
    emojis: [['😀'], ['😁']],
  },
  nature: {
    height: 120,
    top: 250,
    emojis: [['🌲'], ['🌳']],
  },
};

const createComponent = (propsData = {}) => {
  wrapper = shallowMount(VirtualList, {
    propsData: {
      categories: defaultCategories,
      ...propsData,
    },
  });
};

const findContainer = () => wrapper.find('[data-testid="virtual-list-container"]');
const findCategories = () => wrapper.findAllComponents(Category);
const findCategoryWrappers = () => wrapper.findAll('[data-testid="category-wrapper"]');

describe('VirtualList component', () => {
  describe('default rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the container with correct height', () => {
      expect(findContainer().exists()).toBe(true);
      expect(findContainer().attributes('style')).toContain('height: 253px');
    });

    it('renders Category components with correct props', () => {
      const categories = findCategories();
      expect(categories).toHaveLength(3);

      categories.wrappers.forEach((category) => {
        expect(category.props('category')).toEqual(expect.any(String));
        expect(category.props('emojis')).toEqual(expect.any(Array));
      });
    });

    it('renders container with overflow-y-auto class', () => {
      expect(findContainer().classes()).toContain('gl-overflow-y-auto');
    });

    it('renders category wrappers with correct structure', () => {
      createComponent();
      const wrappers = findCategoryWrappers();

      expect(wrappers).toHaveLength(3);
      wrappers.wrappers.forEach((w) => {
        expect(w.attributes('style')).toMatch(/height: \d+px/);
      });
    });
  });

  describe('when user clicks on an emoji', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits select-emoji', async () => {
      const category = findCategories().at(0);
      category.vm.$emit('click', { category: 'activity', emoji: 'thumbsup' });
      await nextTick();

      expect(wrapper.emitted('select-emoji')).toHaveLength(1);
      expect(wrapper.emitted('select-emoji')[0][0]).toEqual({
        category: 'activity',
        emoji: 'thumbsup',
      });
    });
  });

  describe('when searching', () => {
    it('renders the full categories list without filtering', () => {
      createComponent();
      const categories = findCategories();
      expect(categories).toHaveLength(3);

      const categoryNames = categories.wrappers.map((cat) => cat.props('category'));
      expect(categoryNames).toEqual(['activity', 'people', 'nature']);
    });
  });

  describe('when not searching', () => {
    it('filters categories using virtual list', () => {
      const filteredCategories = {
        activity: {
          height: 100,
          top: 0,
          emojis: [['👍']],
        },
      };

      createComponent({ categories: filteredCategories });
      const categories = findCategories();
      expect(categories).toHaveLength(1);

      const categoryNames = categories.wrappers.map((cat) => cat.props('category'));
      expect(categoryNames).toEqual(['activity']);
    });
  });
});
