import { mount } from '@vue/test-utils';
import { range } from 'lodash';
import { GlLabel } from '@gitlab/ui';
import IssueCardInner from '~/boards/components/issue_card_inner.vue';
import defaultStore from '~/boards/stores';
import eventHub from '~/boards/eventhub';
import { updateHistory } from '~/lib/utils/url_utility';
import { mockLabelList } from './mock_data';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/boards/eventhub');

describe('Issue card component', () => {
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

  const createWrapper = (props = {}, store = defaultStore) => {
    wrapper = mount(IssueCardInner, {
      store,
      propsData: {
        list,
        issue,
        ...props,
      },
      stubs: {
        GlLabel: true,
      },
      provide: {
        groupId: null,
        rootPath: '/',
        scopedLabelsAvailable: false,
      },
    });
  };

  beforeEach(() => {
    list = mockLabelList;
    issue = {
      title: 'Testing',
      id: 1,
      iid: 1,
      confidential: false,
      labels: [list.label],
      assignees: [],
      referencePath: '#1',
      webUrl: '/test/1',
      weight: 1,
    };

    createWrapper({ issue, list });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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

  it('does not render blocked icon', () => {
    expect(wrapper.find('.issue-blocked-icon').exists()).toBe(false);
  });

  it('renders issue ID with #', () => {
    expect(wrapper.find('.board-card-number').text()).toContain(`#${issue.id}`);
  });

  it('does not render assignee', () => {
    expect(wrapper.find('.board-card-assignee .avatar').exists()).toBe(false);
  });

  describe('confidential issue', () => {
    beforeEach(() => {
      wrapper.setProps({
        issue: {
          ...wrapper.props('issue'),
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
          issue: {
            ...wrapper.props('issue'),
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
        wrapper.props('issue').updateData({
          ...wrapper.props('issue'),
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
          issue: {
            ...wrapper.props('issue'),
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
        issue: {
          ...wrapper.props('issue'),
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
        const { assignees } = wrapper.props('issue');
        assignees.push({
          id: 5,
          name: 'user5',
          username: 'user5',
          avatarUrl: 'test_image',
        });

        wrapper.setProps({
          issue: {
            ...wrapper.props('issue'),
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
          ...wrapper.props('issue').assignees,
          ...range(5, 103).map((i) => ({
            id: i,
            name: 'name',
            username: 'username',
            avatarUrl: 'test_image',
          })),
        ];
        wrapper.setProps({
          issue: {
            ...wrapper.props('issue'),
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
      wrapper.setProps({ issue: { ...issue, labels: [list.label, label1] } });
    });

    it('does not render list label but renders all other labels', () => {
      expect(wrapper.findAll(GlLabel).length).toBe(1);
      const label = wrapper.find(GlLabel);
      expect(label.props('title')).toEqual(label1.title);
      expect(label.props('description')).toEqual(label1.description);
      expect(label.props('backgroundColor')).toEqual(label1.color);
    });

    it('does not render label if label does not have an ID', async () => {
      wrapper.setProps({ issue: { ...issue, labels: [label1, { title: 'closed' }] } });

      await wrapper.vm.$nextTick();

      expect(wrapper.findAll(GlLabel).length).toBe(1);
      expect(wrapper.text()).not.toContain('closed');
    });
  });

  describe('blocked', () => {
    beforeEach(() => {
      wrapper.setProps({
        issue: {
          ...wrapper.props('issue'),
          blocked: true,
        },
      });
    });

    it('renders blocked icon if issue is blocked', () => {
      expect(wrapper.find('.issue-blocked-icon').exists()).toBe(true);
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
});
