/* global ListAssignee, ListLabel, ListIssue */
import { GlLabel } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { range } from 'lodash';
import '~/boards/models/label';
import '~/boards/models/assignee';
import '~/boards/models/issue';
import '~/boards/models/list';
import IssueCardInner from '~/boards/components/issue_card_inner_deprecated.vue';
import store from '~/boards/stores';
import { listObj } from './mock_data';

describe('Issue card component', () => {
  const user = new ListAssignee({
    id: 1,
    name: 'testing 123',
    username: 'test',
    avatar: 'test_image',
  });

  const label1 = new ListLabel({
    id: 3,
    title: 'testing 123',
    color: '#000CFF',
    text_color: 'white',
    description: 'test',
  });

  let wrapper;
  let issue;
  let list;

  beforeEach(() => {
    list = { ...listObj, type: 'label' };
    issue = new ListIssue({
      title: 'Testing',
      id: 1,
      iid: 1,
      confidential: false,
      labels: [list.label],
      assignees: [],
      reference_path: '#1',
      real_path: '/test/1',
      weight: 1,
    });
    wrapper = mount(IssueCardInner, {
      propsData: {
        list,
        issue,
      },
      store,
      stubs: {
        GlLabel: true,
      },
      provide: {
        groupId: null,
        rootPath: '/',
      },
    });
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

  it('renders confidential icon', (done) => {
    wrapper.setProps({
      issue: {
        ...wrapper.props('issue'),
        confidential: true,
      },
    });
    wrapper.vm.$nextTick(() => {
      expect(wrapper.find('.confidential-icon').exists()).toBe(true);
      done();
    });
  });

  it('renders issue ID with #', () => {
    expect(wrapper.find('.board-card-number').text()).toContain(`#${issue.id}`);
  });

  describe('assignee', () => {
    it('does not render assignee', () => {
      expect(wrapper.find('.board-card-assignee .avatar').exists()).toBe(false);
    });

    describe('exists', () => {
      beforeEach((done) => {
        wrapper.setProps({
          issue: {
            ...wrapper.props('issue'),
            assignees: [user],
            updateData(newData) {
              Object.assign(this, newData);
            },
          },
        });

        wrapper.vm.$nextTick(done);
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

      it('renders the avatar using avatar_url property', (done) => {
        wrapper.props('issue').updateData({
          ...wrapper.props('issue'),
          assignees: [
            {
              id: '1',
              name: 'test',
              state: 'active',
              username: 'test_name',
              avatar_url: 'test_image_from_avatar_url',
            },
          ],
        });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find('.board-card-assignee img').attributes('src')).toBe(
            'test_image_from_avatar_url?width=24',
          );
          done();
        });
      });
    });

    describe('assignee default avatar', () => {
      beforeEach((done) => {
        global.gon.default_avatar_url = 'default_avatar';

        wrapper.setProps({
          issue: {
            ...wrapper.props('issue'),
            assignees: [
              new ListAssignee({
                id: 1,
                name: 'testing 123',
                username: 'test',
              }),
            ],
          },
        });

        wrapper.vm.$nextTick(done);
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
    beforeEach((done) => {
      wrapper.setProps({
        issue: {
          ...wrapper.props('issue'),
          assignees: [
            new ListAssignee({
              id: 2,
              name: 'user2',
              username: 'user2',
              avatar: 'test_image',
            }),
            new ListAssignee({
              id: 3,
              name: 'user3',
              username: 'user3',
              avatar: 'test_image',
            }),
            new ListAssignee({
              id: 4,
              name: 'user4',
              username: 'user4',
              avatar: 'test_image',
            }),
          ],
        },
      });

      wrapper.vm.$nextTick(done);
    });

    it('renders all three assignees', () => {
      expect(wrapper.findAll('.board-card-assignee .avatar').length).toEqual(3);
    });

    describe('more than three assignees', () => {
      beforeEach((done) => {
        const { assignees } = wrapper.props('issue');
        assignees.push(
          new ListAssignee({
            id: 5,
            name: 'user5',
            username: 'user5',
            avatar: 'test_image',
          }),
        );

        wrapper.setProps({
          issue: {
            ...wrapper.props('issue'),
            assignees,
          },
        });
        wrapper.vm.$nextTick(done);
      });

      it('renders more avatar counter', () => {
        expect(wrapper.find('.board-card-assignee .avatar-counter').text().trim()).toEqual('+2');
      });

      it('renders two assignees', () => {
        expect(wrapper.findAll('.board-card-assignee .avatar').length).toEqual(2);
      });

      it('renders 99+ avatar counter', (done) => {
        const assignees = [
          ...wrapper.props('issue').assignees,
          ...range(5, 103).map(
            (i) =>
              new ListAssignee({
                id: i,
                name: 'name',
                username: 'username',
                avatar: 'test_image',
              }),
          ),
        ];
        wrapper.setProps({
          issue: {
            ...wrapper.props('issue'),
            assignees,
          },
        });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find('.board-card-assignee .avatar-counter').text().trim()).toEqual('99+');
          done();
        });
      });
    });
  });

  describe('labels', () => {
    beforeEach((done) => {
      issue.addLabel(label1);
      wrapper.setProps({ issue: { ...issue } });

      wrapper.vm.$nextTick(done);
    });

    it('does not render list label but renders all other labels', () => {
      expect(wrapper.findAll(GlLabel).length).toBe(1);
      const label = wrapper.find(GlLabel);
      expect(label.props('title')).toEqual(label1.title);
      expect(label.props('description')).toEqual(label1.description);
      expect(label.props('backgroundColor')).toEqual(label1.color);
    });

    it('does not render label if label does not have an ID', (done) => {
      issue.addLabel(
        new ListLabel({
          title: 'closed',
        }),
      );
      wrapper.setProps({ issue: { ...issue } });
      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.findAll(GlLabel).length).toBe(1);
          expect(wrapper.text()).not.toContain('closed');
          done();
        })
        .catch(done.fail);
    });
  });

  describe('blocked', () => {
    beforeEach((done) => {
      wrapper.setProps({
        issue: {
          ...wrapper.props('issue'),
          blocked: true,
        },
      });
      wrapper.vm.$nextTick(done);
    });

    it('renders blocked icon if issue is blocked', () => {
      expect(wrapper.find('.issue-blocked-icon').exists()).toBe(true);
    });
  });
});
