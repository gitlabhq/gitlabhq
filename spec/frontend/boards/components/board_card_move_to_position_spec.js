import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import { mockList, mockIssue2, mockIssue, mockIssue3, mockIssue4 } from 'jest/boards/mock_data';
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

  const createStoreOptions = () => {
    const state = {
      pageInfoByListId: {
        'gid://gitlab/List/1': {},
        'gid://gitlab/List/2': { hasNextPage: true },
      },
    };
    const getters = {
      getBoardItemsByList: () => () => [mockIssue, mockIssue2, mockIssue3, mockIssue4],
    };
    const actions = {
      moveItem: jest.fn(),
    };

    return {
      state,
      getters,
      actions,
    };
  };

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
    store = new Vuex.Store(createStoreOptions());
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

      it('is opened on the click of vertical ellipsis and has 1 dropdown items when number of list items > 10', () => {
        wrapper.destroy();

        createComponent({
          list: {
            ...mockList,
            id: 'gid://gitlab/List/2',
          },
        });
        findMoveToPositionDropdown().vm.$emit('click');
        expect(findDropdownItems()).toHaveLength(1);
      });
    });

    describe('Dropdown options', () => {
      beforeEach(() => {
        createComponent({ index: 1 });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        dispatch = jest.spyOn(store, 'dispatch').mockImplementation(() => {});
      });

      afterEach(() => {
        unmockTracking();
      });

      it.each`
        dropdownIndex | dropdownLabel                                   | trackLabel         | moveAfterId     | moveBeforeId
        ${0}          | ${BoardCardMoveToPosition.i18n.moveToStartText} | ${'move_to_start'} | ${mockIssue.id} | ${undefined}
        ${1}          | ${BoardCardMoveToPosition.i18n.moveToEndText}   | ${'move_to_end'}   | ${undefined}    | ${mockIssue4.id}
      `(
        'on click of dropdown index $dropdownIndex with label $dropdownLabel should call moveItem action with tracking label $trackLabel',
        async ({ dropdownIndex, dropdownLabel, trackLabel, moveAfterId, moveBeforeId }) => {
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
          expect(dispatch).toHaveBeenCalledWith('moveItem', {
            fromListId: mockList.id,
            itemId: mockIssue2.id,
            itemIid: mockIssue2.iid,
            itemPath: mockIssue2.referencePath,
            moveBeforeId,
            moveAfterId,
            toListId: mockList.id,
          });
        },
      );
    });
  });
});
