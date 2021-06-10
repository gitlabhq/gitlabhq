import { GlDropdownItem, GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_GROUPS } from 'jest/search/mock_data';
import { truncateNamespace } from '~/lib/utils/text_utility';
import SearchableDropdownItem from '~/search/topbar/components/searchable_dropdown_item.vue';
import { GROUP_DATA } from '~/search/topbar/constants';

describe('Global Search Searchable Dropdown Item', () => {
  let wrapper;

  const defaultProps = {
    item: MOCK_GROUPS[0],
    selectedItem: MOCK_GROUPS[0],
    name: GROUP_DATA.name,
    fullName: GROUP_DATA.fullName,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(SearchableDropdownItem, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findGlAvatar = () => wrapper.findComponent(GlAvatar);
  const findDropdownTitle = () => wrapper.findByTestId('item-title');
  const findDropdownSubtitle = () => wrapper.findByTestId('item-namespace');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders GlDropdownItem', () => {
        expect(findGlDropdownItem().exists()).toBe(true);
      });

      it('renders GlAvatar', () => {
        expect(findGlAvatar().exists()).toBe(true);
      });

      it('renders Dropdown Title correctly', () => {
        const titleEl = findDropdownTitle();

        expect(titleEl.exists()).toBe(true);
        expect(titleEl.text()).toBe(MOCK_GROUPS[0][GROUP_DATA.name]);
      });

      it('renders Dropdown Subtitle correctly', () => {
        const subtitleEl = findDropdownSubtitle();

        expect(subtitleEl.exists()).toBe(true);
        expect(subtitleEl.text()).toBe(truncateNamespace(MOCK_GROUPS[0][GROUP_DATA.fullName]));
      });
    });

    describe('when item === selectedItem', () => {
      beforeEach(() => {
        createComponent({ item: MOCK_GROUPS[0], selectedItem: MOCK_GROUPS[0] });
      });

      it('marks the dropdown as checked', () => {
        expect(findGlDropdownItem().attributes('ischecked')).toBe('true');
      });
    });

    describe('when item !== selectedItem', () => {
      beforeEach(() => {
        createComponent({ item: MOCK_GROUPS[0], selectedItem: MOCK_GROUPS[1] });
      });

      it('marks the dropdown as not checked', () => {
        expect(findGlDropdownItem().attributes('ischecked')).toBeUndefined();
      });
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('clicking the dropdown item $emits change with the item', () => {
      findGlDropdownItem().vm.$emit('click');

      expect(wrapper.emitted('change')[0]).toEqual([MOCK_GROUPS[0]]);
    });
  });
});
