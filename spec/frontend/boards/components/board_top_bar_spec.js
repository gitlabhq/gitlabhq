import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import BoardTopBar from '~/boards/components/board_top_bar.vue';
import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import BoardsSelector from '~/boards/components/boards_selector.vue';
import ConfigToggle from '~/boards/components/config_toggle.vue';
import IssueBoardFilteredSearch from '~/boards/components/issue_board_filtered_search.vue';
import NewBoardButton from '~/boards/components/new_board_button.vue';
import ToggleFocus from '~/boards/components/toggle_focus.vue';

describe('BoardTopBar', () => {
  let wrapper;

  Vue.use(Vuex);

  const createStore = () => {
    return new Vuex.Store({
      state: {},
    });
  };

  const createComponent = ({ provide = {} } = {}) => {
    const store = createStore();
    wrapper = shallowMount(BoardTopBar, {
      store,
      provide: {
        swimlanesFeatureAvailable: false,
        canAdminList: false,
        isSignedIn: false,
        fullPath: 'gitlab-org',
        boardType: 'group',
        releasesFetchPath: '/releases',
        isIssueBoard: true,
        isGroupBoard: true,
        ...provide,
      },
      stubs: { IssueBoardFilteredSearch },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('base template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders BoardsSelector component', () => {
      expect(wrapper.findComponent(BoardsSelector).exists()).toBe(true);
    });

    it('renders IssueBoardFilteredSearch component', () => {
      expect(wrapper.findComponent(IssueBoardFilteredSearch).exists()).toBe(true);
    });

    it('renders NewBoardButton component', () => {
      expect(wrapper.findComponent(NewBoardButton).exists()).toBe(true);
    });

    it('renders ConfigToggle component', () => {
      expect(wrapper.findComponent(ConfigToggle).exists()).toBe(true);
    });

    it('renders ToggleFocus component', () => {
      expect(wrapper.findComponent(ToggleFocus).exists()).toBe(true);
    });

    it('does not render BoardAddNewColumnTrigger component', () => {
      expect(wrapper.findComponent(BoardAddNewColumnTrigger).exists()).toBe(false);
    });
  });

  describe('when user can admin list', () => {
    beforeEach(() => {
      createComponent({ provide: { canAdminList: true } });
    });

    it('renders BoardAddNewColumnTrigger component', () => {
      expect(wrapper.findComponent(BoardAddNewColumnTrigger).exists()).toBe(true);
    });
  });
});
