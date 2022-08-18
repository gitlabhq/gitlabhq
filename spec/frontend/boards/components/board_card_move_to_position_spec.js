import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import { createStore } from '~/boards/stores';
import { mockList, mockIssue2 } from 'jest/boards/mock_data';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

Vue.use(Vuex);

const dropdownOptions = [
  BoardCardMoveToPosition.i18n.moveToStartText,
  BoardCardMoveToPosition.i18n.moveToEndText,
];

describe('Board Card Move to position', () => {
  let wrapper;
  let trackingSpy;
  let store;
  let dispatch;

  store = new Vuex.Store();

  const createComponent = (propsData) => {
    wrapper = shallowMountExtended(BoardCardMoveToPosition, {
      store,
      propsData: {
        item: mockIssue2,
        list: mockList,
        index: 0,
        ...propsData,
      },
      stubs: {
        GlDropdown,
        GlDropdownItem,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findEllipsesButton = () => wrapper.findByTestId('move-card-dropdown');
  const findMoveToPositionDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => findMoveToPositionDropdown().findAllComponents(GlDropdownItem);
  const findDropdownItemAtIndex = (index) => findDropdownItems().at(index);

  describe('Dropdown', () => {
    describe('Dropdown button', () => {
      it('has an icon with vertical ellipsis', () => {
        expect(findEllipsesButton().exists()).toBe(true);
        expect(findMoveToPositionDropdown().props('icon')).toBe('ellipsis_v');
      });

      it('is opened on the click of vertical ellipsis and has 2 dropdown items when number of list items < 10', () => {
        findMoveToPositionDropdown().vm.$emit('click');

        expect(findDropdownItems()).toHaveLength(dropdownOptions.length);
      });
    });

    describe('Dropdown options', () => {
      beforeEach(() => {
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        dispatch = jest.spyOn(store, 'dispatch').mockImplementation(() => {});
      });

      afterEach(() => {
        unmockTracking();
      });

      it.each`
        dropdownIndex | dropdownLabel                                   | startActionCalledTimes | trackLabel
        ${0}          | ${BoardCardMoveToPosition.i18n.moveToStartText} | ${0}                   | ${'move_to_start'}
        ${1}          | ${BoardCardMoveToPosition.i18n.moveToEndText}   | ${1}                   | ${'move_to_end'}
      `(
        'on click of dropdown index $dropdownIndex with label $dropdownLabel should call moveItem action with tracking label $trackLabel',
        async ({ dropdownIndex, startActionCalledTimes, dropdownLabel, trackLabel }) => {
          await findEllipsesButton().vm.$emit('click');

          expect(findDropdownItemAtIndex(dropdownIndex).text()).toBe(dropdownLabel);
          await findDropdownItemAtIndex(dropdownIndex).vm.$emit('click', {
            stopPropagation: () => {},
          });

          await nextTick();

          expect(trackingSpy).toHaveBeenCalledWith('boards:list', 'click_toggle_button', {
            category: 'boards:list',
            label: trackLabel,
            property: 'type_card',
          });
          expect(dispatch).toHaveBeenCalledTimes(startActionCalledTimes);
          if (startActionCalledTimes) {
            expect(dispatch).toHaveBeenCalledWith('moveItem', {
              fromListId: mockList.id,
              itemId: mockIssue2.id,
              itemIid: mockIssue2.iid,
              itemPath: mockIssue2.referencePath,
              moveBeforeId: undefined,
              moveAfterId: undefined,
              toListId: mockList.id,
            });
          }
        },
      );
    });
  });
});
