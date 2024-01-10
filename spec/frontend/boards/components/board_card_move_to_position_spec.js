import { shallowMount } from '@vue/test-utils';
import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import {
  BOARD_CARD_MOVE_TO_POSITIONS_START_OPTION,
  BOARD_CARD_MOVE_TO_POSITIONS_END_OPTION,
} from '~/boards/constants';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import { mockList, mockIssue2 } from 'jest/boards/mock_data';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

const dropdownOptions = [
  {
    text: BOARD_CARD_MOVE_TO_POSITIONS_START_OPTION,
    action: jest.fn(),
  },
  {
    text: BOARD_CARD_MOVE_TO_POSITIONS_END_OPTION,
    action: jest.fn(),
  },
];

describe('Board Card Move to position', () => {
  let wrapper;
  let trackingSpy;
  const itemIndex = 1;

  const createComponent = (propsData) => {
    wrapper = shallowMount(BoardCardMoveToPosition, {
      propsData: {
        item: mockIssue2,
        list: mockList,
        listItemsLength: 3,
        index: 0,
        ...propsData,
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findMoveToPositionDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItems = () =>
    findMoveToPositionDropdown().findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemAtIndex = (index) => findDropdownItems().at(index);

  describe('Dropdown', () => {
    describe('Dropdown button', () => {
      it('has an icon with vertical ellipsis', () => {
        expect(findMoveToPositionDropdown().exists()).toBe(true);
        expect(findMoveToPositionDropdown().props('icon')).toBe('ellipsis_v');
      });

      it('is opened on the click of vertical ellipsis and has 2 dropdown items when number of list items < 10', () => {
        findMoveToPositionDropdown().vm.$emit('shown');
        expect(findDropdownItems()).toHaveLength(dropdownOptions.length);
      });
    });

    describe('Dropdown options', () => {
      beforeEach(() => {
        createComponent({ index: itemIndex }, true);
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      afterEach(() => {
        unmockTracking();
      });

      it.each`
        dropdownIndex | dropdownItem          | trackLabel         | positionInList
        ${0}          | ${dropdownOptions[0]} | ${'move_to_start'} | ${0}
        ${1}          | ${dropdownOptions[1]} | ${'move_to_end'}   | ${-1}
      `(
        'on click of dropdown index $dropdownIndex with label $dropdownLabel emits moveToPosition event with tracking label $trackLabel',
        async ({ dropdownIndex, dropdownItem, trackLabel, positionInList }) => {
          await findMoveToPositionDropdown().vm.$emit('shown');

          expect(findDropdownItemAtIndex(dropdownIndex).text()).toBe(dropdownItem.text);

          await findMoveToPositionDropdown().vm.$emit('action', dropdownItem);

          expect(trackingSpy).toHaveBeenCalledWith('boards:list', 'click_toggle_button', {
            category: 'boards:list',
            label: trackLabel,
            property: 'type_card',
          });

          expect(wrapper.emitted('moveToPosition')).toEqual([[positionInList]]);
        },
      );
    });
  });
});
