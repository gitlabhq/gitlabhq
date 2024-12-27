import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlobalSearchFrequentItems from '~/super_sidebar/components/global_search/components/frequent_items.vue';
import FrequentItem from '~/super_sidebar/components/global_search/components/frequent_item.vue';
import FrequentItemSkeleton from '~/super_sidebar/components/global_search/components/frequent_item_skeleton.vue';
import { frecentGroupsMock } from 'jest/super_sidebar/mock_data';
import SearchResultHoverLayover from '~/super_sidebar/components/global_search/components/global_search_hover_overlay.vue';

describe('FrequentlyVisitedItems', () => {
  let wrapper;
  const mockProps = {
    emptyStateText: 'mock empty state text',
    groupName: 'mock group name',
    viewAllItemsText: 'View all items',
    viewAllItemsIcon: 'question-o',
    viewAllItemsPath: '/mock/all_items',
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(GlobalSearchFrequentItems, {
      propsData: {
        ...mockProps,
        ...props,
      },
      stubs: {
        GlDisclosureDropdownGroup,
      },
    });
  };

  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findSkeleton = () => wrapper.findComponent(FrequentItemSkeleton);
  const findItemRenderer = (root) => root.findComponent(FrequentItem);
  const findLayover = () => wrapper.findComponent(SearchResultHoverLayover);

  describe('common behavior', () => {
    beforeEach(() => {
      createComponent({
        items: frecentGroupsMock,
      });
    });

    it('renders the group name', () => {
      expect(wrapper.text()).toContain(mockProps.groupName);
    });

    it('renders the layover component', () => {
      expect(findLayover().exists()).toBe(true);
    });

    it('renders the view all items link', () => {
      const lastItem = findItems().at(1);
      expect(lastItem.props('item')).toMatchObject({
        text: mockProps.viewAllItemsText,
        href: mockProps.viewAllItemsPath,
      });

      const icon = lastItem.findComponent(GlIcon);
      expect(icon.props('name')).toBe(mockProps.viewAllItemsIcon);
    });
  });

  describe('while items are being fetched', () => {
    beforeEach(() => {
      createComponent({
        loading: true,
      });
    });

    it('shows the loading state', () => {
      expect(findSkeleton().exists()).toBe(true);
    });

    it('does not show the empty state', () => {
      expect(wrapper.text()).not.toContain(mockProps.emptyStateText);
    });
  });

  describe('when there are no items', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not show the loading state', () => {
      expect(findSkeleton().exists()).toBe(false);
    });

    it('shows the empty state', () => {
      expect(wrapper.text()).toContain(mockProps.emptyStateText);
    });
  });

  describe.each`
    description              | relativeUrl
    ${'with relativeUrl'}    | ${'/gitlab'}
    ${'without relativeUrl'} | ${''}
  `('when there are items $description', ({ relativeUrl }) => {
    beforeEach(() => {
      gon.relative_url_root = relativeUrl;
      createComponent({
        items: frecentGroupsMock,
      });
    });

    it('renders the items', () => {
      const items = findItems();

      frecentGroupsMock.forEach((item, index) => {
        const dropdownItem = items.at(index);

        // Check GlDisclosureDropdownItem's item has the right structure
        expect(dropdownItem.props('item')).toMatchObject({
          text: item.name,
          href: `${relativeUrl}/${item.fullPath}`,
        });

        // Check FrequentItem's item has the right structure
        expect(findItemRenderer(dropdownItem).props('item')).toMatchObject({
          id: item.id,
          title: item.name,
          subtitle: expect.any(String),
          avatar: item.avatarUrl,
        });
      });
    });

    it('does not show the loading state', () => {
      expect(findSkeleton().exists()).toBe(false);
    });

    it('does not show the empty state', () => {
      expect(wrapper.text()).not.toContain(mockProps.emptyStateText);
    });
  });
});
