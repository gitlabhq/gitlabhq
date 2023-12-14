import { GlDropdown, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';

describe('DropdownWidget component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(DropdownWidget, {
      propsData: {
        options: [
          {
            id: '1',
            title: 'Option 1',
          },
          {
            id: '2',
            title: 'Option 2',
          },
        ],
        ...props,
      },
      stubs: {
        GlDropdown: stubComponent(GlDropdown, {
          methods: {
            hide: jest.fn(),
          },
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('passes default selectText prop to dropdown', () => {
    expect(findDropdown().props('text')).toBe('Select');
  });

  describe('when dropdown is open', () => {
    beforeEach(async () => {
      findDropdown().vm.$emit('show');
      await nextTick();
    });

    it('emits search event when typing in search box', () => {
      const searchTerm = 'searchTerm';
      findSearch().vm.$emit('input', searchTerm);

      expect(wrapper.emitted('set-search')).toEqual([[searchTerm]]);
    });

    it('renders one selectable item per passed option', () => {
      expect(findDropdownItems()).toHaveLength(2);
    });

    it('emits set-option event when clicking on an option', async () => {
      wrapper.findAll('[data-testid="unselected-option"]').at(1).trigger('click');
      await nextTick();

      expect(wrapper.emitted('set-option')).toEqual([[wrapper.props().options[1]]]);
    });
  });

  describe('when options are users', () => {
    const mockUser = {
      id: 1,
      name: 'User name',
      username: 'username',
      avatarUrl: 'foo/bar',
    };

    beforeEach(() => {
      createComponent({ props: { options: [mockUser] } });
    });

    it('passes user related props to dropdown item', () => {
      expect(findDropdownItems().at(0).props('avatarUrl')).toBe(mockUser.avatarUrl);
      expect(findDropdownItems().at(0).props('secondaryText')).toBe(mockUser.username);
    });
  });
});
