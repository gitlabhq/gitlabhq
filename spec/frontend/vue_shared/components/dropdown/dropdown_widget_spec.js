import { GlDropdown, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';

describe('DropdownWidget component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAll(GlDropdownItem);
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
        GlDropdown,
      },
    });

    // We need to mock out `showDropdown` which
    // invokes `show` method of BDropdown used inside GlDropdown.
    // Context: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54895#note_524281679
    jest.spyOn(wrapper.vm, 'showDropdown').mockImplementation();
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('passes default selectText prop to dropdown', () => {
    expect(findDropdown().props('text')).toBe('Select');
  });

  describe('when dropdown is open', () => {
    beforeEach(async () => {
      findDropdown().vm.$emit('show');
      await wrapper.vm.$nextTick();
    });

    it('emits search event when typing in search box', () => {
      const searchTerm = 'searchTerm';
      findSearch().vm.$emit('input', searchTerm);

      expect(wrapper.emitted('set-search')).toEqual([[searchTerm]]);
    });

    it('renders one selectable item per passed option', async () => {
      expect(findDropdownItems()).toHaveLength(2);
    });

    it('emits set-option event when clicking on an option', async () => {
      wrapper
        .findAll('[data-testid="unselected-option"]')
        .at(1)
        .vm.$emit('click', new Event('click'));
      await wrapper.vm.$nextTick();

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
