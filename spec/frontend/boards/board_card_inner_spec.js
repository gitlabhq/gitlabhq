import { GlLabel, GlLoadingIcon, GlTooltip } from '@gitlab/ui';
import { range } from 'lodash';
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BoardBlockedIcon from '~/boards/components/board_blocked_icon.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import { issuableTypes } from '~/boards/constants';
import eventHub from '~/boards/eventhub';
import defaultStore from '~/boards/stores';
import { updateHistory } from '~/lib/utils/url_utility';
import { mockLabelList, mockIssue } from './mock_data';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/boards/eventhub');

describe('Board card component', () => {
  const user = {
    id: 1,
    name: 'testing 123',
    username: 'test',
    avatarUrl: 'test_image',
  };

  const label1 = {
    id: 3,
    title: 'testing 123',
    color: '#000CFF',
    textColor: 'white',
    description: 'test',
  };

  let wrapper;
  let issue;
  let list;
  let store;

  const findBoardBlockedIcon = () => wrapper.find(BoardBlockedIcon);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEpicCountablesTotalTooltip = () => wrapper.findComponent(GlTooltip);
  const findEpicCountables = () => wrapper.findByTestId('epic-countables');
  const findEpicCountablesBadgeIssues = () => wrapper.findByTestId('epic-countables-counts-issues');
  const findEpicCountablesBadgeWeight = () => wrapper.findByTestId('epic-countables-weight-issues');
  const findEpicBadgeProgress = () => wrapper.findByTestId('epic-progress');
  const findEpicCountablesTotalWeight = () => wrapper.findByTestId('epic-countables-total-weight');
  const findEpicProgressTooltip = () => wrapper.findByTestId('epic-progress-tooltip-content');

  const createStore = ({ isEpicBoard = false } = {}) => {
    store = new Vuex.Store({
      ...defaultStore,
      state: {
        ...defaultStore.state,
        issuableType: issuableTypes.issue,
      },
      getters: {
        isGroupBoard: () => true,
        isEpicBoard: () => isEpicBoard,
        isProjectBoard: () => false,
      },
    });
  };

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(BoardCardInner, {
      store,
      propsData: {
        list,
        item: issue,
        ...props,
      },
      stubs: {
        GlLabel: true,
        GlLoadingIcon: true,
      },
      mocks: {
        $apollo: {
          queries: {
            blockingIssuables: { loading: false },
          },
        },
      },
      provide: {
        rootPath: '/',
        scopedLabelsAvailable: false,
      },
    });
  };

  beforeEach(() => {
    list = mockLabelList;
    issue = {
      ...mockIssue,
      labels: [list.label],
      assignees: [],
      weight: 1,
    };

    createStore();
    createWrapper({ item: issue, list });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
    jest.clearAllMocks();
  });

  it('renders issue title', () => {
    expect(wrapper.find('.board-card-title').text()).toContain(issue.title);
  });

  it('includes issue base in link', () => {
    expect(wrapper.find('.board-card-title a').attributes('href')).toContain('/test');
  });

  it('includes issue title on link', () => {
    expect(wrapper.find('.board-card-title a').attributes('title')).toBe(issue.title);
  });

  it('does not render confidential icon', () => {
    expect(wrapper.find('.confidential-icon').exists()).toBe(false);
  });

  it('renders issue ID with #', () => {
    expect(wrapper.find('.board-card-number').text()).toContain(`#${issue.iid}`);
  });

  it('does not render assignee', () => {
    expect(wrapper.find('.board-card-assignee .avatar').exists()).toBe(false);
  });

  it('does not render loading icon', () => {
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
  });

  describe('blocked', () => {
    it('renders blocked icon if issue is blocked', async () => {
      createWrapper({
        item: {
          ...issue,
          blocked: true,
        },
      });

      expect(findBoardBlockedIcon().exists()).toBe(true);
    });

    it('does not show blocked icon if issue is not blocked', () => {
      createWrapper({
        item: {
          ...issue,
          blocked: false,
        },
      });

      expect(findBoardBlockedIcon().exists()).toBe(false);
    });
  });

  describe('confidential issue', () => {
    beforeEach(() => {
      wrapper.setProps({
        item: {
          ...wrapper.props('item'),
          confidential: true,
        },
      });
    });

    it('renders confidential icon', () => {
      expect(wrapper.find('.confidential-icon').exists()).toBe(true);
    });
  });

  describe('with assignee', () => {
    describe('with avatar', () => {
      beforeEach(() => {
        wrapper.setProps({
          item: {
            ...wrapper.props('item'),
            assignees: [user],
            updateData(newData) {
              Object.assign(this, newData);
            },
          },
        });
      });

      it('renders assignee', () => {
        expect(wrapper.find('.board-card-assignee .avatar').exists()).toBe(true);
      });

      it('sets title', () => {
        expect(wrapper.find('.js-assignee-tooltip').text()).toContain(`${user.name}`);
      });

      it('sets users path', () => {
        expect(wrapper.find('.board-card-assignee a').attributes('href')).toBe('/test');
      });

      it('renders avatar', () => {
        expect(wrapper.find('.board-card-assignee img').exists()).toBe(true);
      });

      it('renders the avatar using avatarUrl property', async () => {
        wrapper.props('item').updateData({
          ...wrapper.props('item'),
          assignees: [
            {
              id: '1',
              name: 'test',
              state: 'active',
              username: 'test_name',
              avatarUrl: 'test_image_from_avatar_url',
            },
          ],
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.find('.board-card-assignee img').attributes('src')).toBe(
          'test_image_from_avatar_url?width=24',
        );
      });
    });

    describe('with default avatar', () => {
      beforeEach(() => {
        global.gon.default_avatar_url = 'default_avatar';

        wrapper.setProps({
          item: {
            ...wrapper.props('item'),
            assignees: [
              {
                id: 1,
                name: 'testing 123',
                username: 'test',
              },
            ],
          },
        });
      });

      afterEach(() => {
        global.gon.default_avatar_url = null;
      });

      it('displays defaults avatar if users avatar is null', () => {
        expect(wrapper.find('.board-card-assignee img').exists()).toBe(true);
        expect(wrapper.find('.board-card-assignee img').attributes('src')).toBe(
          'default_avatar?width=24',
        );
      });
    });
  });

  describe('multiple assignees', () => {
    beforeEach(() => {
      wrapper.setProps({
        item: {
          ...wrapper.props('item'),
          assignees: [
            {
              id: 2,
              name: 'user2',
              username: 'user2',
              avatarUrl: 'test_image',
            },
            {
              id: 3,
              name: 'user3',
              username: 'user3',
              avatarUrl: 'test_image',
            },
            {
              id: 4,
              name: 'user4',
              username: 'user4',
              avatarUrl: 'test_image',
            },
          ],
        },
      });
    });

    it('renders all three assignees', () => {
      expect(wrapper.findAll('.board-card-assignee .avatar').length).toEqual(3);
    });

    describe('more than three assignees', () => {
      beforeEach(() => {
        const { assignees } = wrapper.props('item');
        assignees.push({
          id: 5,
          name: 'user5',
          username: 'user5',
          avatarUrl: 'test_image',
        });

        wrapper.setProps({
          item: {
            ...wrapper.props('item'),
            assignees,
          },
        });
      });

      it('renders more avatar counter', () => {
        expect(wrapper.find('.board-card-assignee .avatar-counter').text().trim()).toEqual('+2');
      });

      it('renders two assignees', () => {
        expect(wrapper.findAll('.board-card-assignee .avatar').length).toEqual(2);
      });

      it('renders 99+ avatar counter', async () => {
        const assignees = [
          ...wrapper.props('item').assignees,
          ...range(5, 103).map((i) => ({
            id: i,
            name: 'name',
            username: 'username',
            avatarUrl: 'test_image',
          })),
        ];
        wrapper.setProps({
          item: {
            ...wrapper.props('item'),
            assignees,
          },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.find('.board-card-assignee .avatar-counter').text().trim()).toEqual('99+');
      });
    });
  });

  describe('labels', () => {
    beforeEach(() => {
      wrapper.setProps({ item: { ...issue, labels: [list.label, label1] } });
    });

    it('does not render list label but renders all other labels', () => {
      expect(wrapper.findAll(GlLabel).length).toBe(1);
      const label = wrapper.find(GlLabel);
      expect(label.props('title')).toEqual(label1.title);
      expect(label.props('description')).toEqual(label1.description);
      expect(label.props('backgroundColor')).toEqual(label1.color);
    });

    it('does not render label if label does not have an ID', async () => {
      wrapper.setProps({ item: { ...issue, labels: [label1, { title: 'closed' }] } });

      await wrapper.vm.$nextTick();

      expect(wrapper.findAll(GlLabel).length).toBe(1);
      expect(wrapper.text()).not.toContain('closed');
    });
  });

  describe('filterByLabel method', () => {
    beforeEach(() => {
      delete window.location;

      wrapper.setProps({
        updateFilters: true,
      });
    });

    describe('when selected label is not in the filter', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'performSearch').mockImplementation(() => {});
        window.location = { search: '' };
        wrapper.vm.filterByLabel(label1);
      });

      it('calls updateHistory', () => {
        expect(updateHistory).toHaveBeenCalledTimes(1);
      });

      it('dispatches performSearch vuex action', () => {
        expect(wrapper.vm.performSearch).toHaveBeenCalledTimes(1);
      });

      it('emits updateTokens event', () => {
        expect(eventHub.$emit).toHaveBeenCalledTimes(1);
        expect(eventHub.$emit).toHaveBeenCalledWith('updateTokens');
      });
    });

    describe('when selected label is already in the filter', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'performSearch').mockImplementation(() => {});
        window.location = { search: '?label_name[]=testing%20123' };
        wrapper.vm.filterByLabel(label1);
      });

      it('does not call updateHistory', () => {
        expect(updateHistory).not.toHaveBeenCalled();
      });

      it('does not dispatch performSearch vuex action', () => {
        expect(wrapper.vm.performSearch).not.toHaveBeenCalled();
      });

      it('does not emit updateTokens event', () => {
        expect(eventHub.$emit).not.toHaveBeenCalled();
      });
    });
  });

  describe('loading', () => {
    it('renders loading icon', async () => {
      createWrapper({
        item: {
          ...issue,
          isLoading: true,
        },
      });

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('is an epic board', () => {
    const descendantCounts = {
      closedEpics: 0,
      closedIssues: 0,
      openedEpics: 0,
      openedIssues: 0,
    };

    const descendantWeightSum = {
      closedIssues: 0,
      openedIssues: 0,
    };

    beforeEach(() => {
      createStore({ isEpicBoard: true });
    });

    it('should render if the item has issues', () => {
      createWrapper({
        item: {
          ...issue,
          descendantCounts,
          descendantWeightSum,
          hasIssues: true,
        },
      });

      expect(findEpicCountables().exists()).toBe(true);
    });

    it('should not render if the item does not have issues', () => {
      createWrapper({
        item: {
          ...issue,
          descendantCounts,
          descendantWeightSum,
          hasIssues: false,
        },
      });

      expect(findEpicCountablesBadgeIssues().exists()).toBe(false);
    });

    it('shows render item countBadge, weights, and progress correctly', () => {
      createWrapper({
        item: {
          ...issue,
          descendantCounts: {
            ...descendantCounts,
            openedIssues: 1,
          },
          descendantWeightSum: {
            closedIssues: 10,
            openedIssues: 5,
          },
          hasIssues: true,
        },
      });

      expect(findEpicCountablesBadgeIssues().text()).toBe('1');
      expect(findEpicCountablesBadgeWeight().text()).toBe('15');
      expect(findEpicBadgeProgress().text()).toBe('67%');
    });

    it('does not render progress when weight is zero', () => {
      createWrapper({
        item: {
          ...issue,
          descendantCounts: {
            ...descendantCounts,
            openedIssues: 1,
          },
          descendantWeightSum,
          hasIssues: true,
        },
      });

      expect(findEpicBadgeProgress().exists()).toBe(false);
    });

    it('renders the tooltip with the correct data', () => {
      createWrapper({
        item: {
          ...issue,
          descendantCounts,
          descendantWeightSum: {
            closedIssues: 10,
            openedIssues: 5,
          },
          hasIssues: true,
        },
      });

      const tooltip = findEpicCountablesTotalTooltip();
      expect(tooltip).toBeDefined();

      expect(findEpicCountablesTotalWeight().text()).toBe('15');
      expect(findEpicProgressTooltip().text()).toBe('10 of 15 weight completed');
    });
  });
});
