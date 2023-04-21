import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ItemsList from '~/super_sidebar/components/items_list.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { cachedFrequentProjects } from '../mock_data';

const mockItems = JSON.parse(cachedFrequentProjects);
const [firstMockedProject] = mockItems;

describe('ItemsList component', () => {
  let wrapper;

  const findNavItems = () => wrapper.findAllComponents(NavItem);

  const createWrapper = ({ props = {}, slots = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(ItemsList, {
      propsData: {
        ...props,
      },
      slots,
    });
  };

  it('does not render nav items when there are no items', () => {
    createWrapper();

    expect(findNavItems().length).toBe(0);
  });

  it('renders one nav item per item', () => {
    createWrapper({
      props: {
        items: mockItems,
      },
    });

    expect(findNavItems().length).not.toBe(0);
    expect(findNavItems().length).toBe(mockItems.length);
  });

  it('passes the correct props to the nav items', () => {
    createWrapper({
      props: {
        items: mockItems,
      },
    });
    const firstNavItem = findNavItems().at(0);

    expect(firstNavItem.props('item')).toEqual(firstMockedProject);
  });

  it('renders the `view-all-items` slot', () => {
    const testId = 'view-all-items';
    createWrapper({
      slots: {
        'view-all-items': {
          template: `<div data-testid="${testId}" />`,
        },
      },
    });

    expect(wrapper.findByTestId(testId).exists()).toBe(true);
  });

  describe('item removal', () => {
    const findRemoveButton = () => wrapper.findByTestId('item-remove');
    const mockProject = {
      ...firstMockedProject,
      title: firstMockedProject.name,
    };

    beforeEach(() => {
      createWrapper({
        props: {
          items: [mockProject],
        },
        mountFn: mountExtended,
      });
    });

    it('renders the remove button', () => {
      const itemRemoveButton = findRemoveButton();

      expect(itemRemoveButton.exists()).toBe(true);
      expect(itemRemoveButton.attributes('title')).toBe('Remove');
      expect(itemRemoveButton.findComponent(GlIcon).props('name')).toBe('dash');
    });

    it('emits `remove-item` event with item param when remove button is clicked', () => {
      const itemRemoveButton = findRemoveButton();

      itemRemoveButton.vm.$emit(
        'click',
        { stopPropagation: jest.fn(), preventDefault: jest.fn() },
        mockProject,
      );

      expect(wrapper.emitted('remove-item')).toEqual([[mockProject]]);
    });
  });
});
