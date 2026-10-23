import { GlDropdown, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
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
      findDropdownItems().at(1).vm.$emit('click', new MouseEvent('click'));
      await nextTick();

      expect(wrapper.emitted('set-option')).toEqual([[wrapper.props().options[1]]]);
    });
  });

  describe('with a real dropdown', () => {
    const createMountedComponent = (props = {}) => {
      wrapper = mount(DropdownWidget, {
        propsData: {
          options: [{ id: '1', title: 'Option 1' }],
          ...props,
        },
        attachTo: document.body,
      });
    };

    const openDropdown = async () => {
      findDropdown().vm.show();
      jest.runOnlyPendingTimers();
      await nextTick();
    };

    const clickOption = async () => {
      wrapper.find('[data-testid="unselected-option"]').trigger('click');
      jest.runOnlyPendingTimers();
      await nextTick();
    };

    const isOpen = () => findDropdown().find('.dropdown-menu').classes('show');

    it.each`
      allowMultiselect | open     | hideEvents
      ${true}          | ${true}  | ${undefined}
      ${false}         | ${false} | ${[[expect.any(Object)]]}
    `(
      'keeps the dropdown open on option click: $open, when allowMultiselect is $allowMultiselect',
      async ({ allowMultiselect, open, hideEvents }) => {
        createMountedComponent({ allowMultiselect });
        await openDropdown();
        expect(isOpen()).toBe(true);

        await clickOption();

        expect(wrapper.emitted('set-option')).toEqual([[{ id: '1', title: 'Option 1' }]]);
        expect(isOpen()).toBe(open);
        expect(wrapper.emitted('hide')).toEqual(hideEvents);
      },
    );

    it('emits `hide` when the dropdown closes after an option click', async () => {
      createMountedComponent({ allowMultiselect: true });
      await openDropdown();
      await clickOption();
      findDropdown().vm.hide();
      await nextTick();

      expect(isOpen()).toBe(false);
      expect(wrapper.emitted('hide')).toHaveLength(1);
    });

    it('does not propagate the option click', async () => {
      const onClick = jest.fn();
      createMountedComponent({ allowMultiselect: true });
      document.body.addEventListener('click', onClick);
      await openDropdown();
      await clickOption();
      document.body.removeEventListener('click', onClick);

      expect(onClick).not.toHaveBeenCalled();
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
