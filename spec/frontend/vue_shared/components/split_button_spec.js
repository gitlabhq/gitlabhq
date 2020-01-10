import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import SplitButton from '~/vue_shared/components/split_button.vue';

const mockActionItems = [
  {
    eventName: 'concert',
    title: 'professor',
    description: 'very symphonic',
  },
  {
    eventName: 'apocalypse',
    title: 'captain',
    description: 'warp drive',
  },
];

describe('SplitButton', () => {
  let wrapper;

  const createComponent = propsData => {
    wrapper = shallowMount(SplitButton, {
      propsData,
    });
  };

  const findDropdown = () => wrapper.find(GlDropdown);
  const findDropdownItem = (index = 0) =>
    findDropdown()
      .findAll(GlDropdownItem)
      .at(index);
  const selectItem = index => {
    findDropdownItem(index).vm.$emit('click');

    return wrapper.vm.$nextTick();
  };
  const clickToggleButton = () => {
    findDropdown().vm.$emit('click');

    return wrapper.vm.$nextTick();
  };

  it('fails for empty actionItems', () => {
    const actionItems = [];
    expect(() => createComponent({ actionItems })).toThrow();
  });

  it('fails for single actionItems', () => {
    const actionItems = [mockActionItems[0]];
    expect(() => createComponent({ actionItems })).toThrow();
  });

  it('renders actionItems', () => {
    createComponent({ actionItems: mockActionItems });

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('toggle button text', () => {
    beforeEach(() => {
      createComponent({ actionItems: mockActionItems });
    });

    it('defaults to first actionItems title', () => {
      expect(findDropdown().props().text).toBe(mockActionItems[0].title);
    });

    it('changes to selected actionItems title', () =>
      selectItem(1).then(() => {
        expect(findDropdown().props().text).toBe(mockActionItems[1].title);
      }));
  });

  describe('emitted event', () => {
    let eventHandler;

    beforeEach(() => {
      createComponent({ actionItems: mockActionItems });
    });

    const addEventHandler = ({ eventName }) => {
      eventHandler = jest.fn();
      wrapper.vm.$once(eventName, () => eventHandler());
    };

    it('defaults to first actionItems event', () => {
      addEventHandler(mockActionItems[0]);

      return clickToggleButton().then(() => {
        expect(eventHandler).toHaveBeenCalled();
      });
    });

    it('changes to selected actionItems event', () =>
      selectItem(1)
        .then(() => addEventHandler(mockActionItems[1]))
        .then(clickToggleButton)
        .then(() => {
          expect(eventHandler).toHaveBeenCalled();
        }));
  });
});
