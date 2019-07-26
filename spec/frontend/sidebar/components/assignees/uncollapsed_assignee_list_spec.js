import Vue from 'vue';
import { mount } from '@vue/test-utils';
import UncollapsedAssigneeList from '~/sidebar/components/assignees/uncollapsed_assignee_list.vue';
import AssigneeAvatarLink from '~/sidebar/components/assignees/assignee_avatar_link.vue';
import { TEST_HOST } from 'helpers/test_constants';
import userDataMock from '../../user_data_mock';
import UsersMockHelper from '../../../helpers/user_mock_data_helper';

const DEFAULT_RENDER_COUNT = 5;

describe('UncollapsedAssigneeList component', () => {
  let wrapper;

  function createComponent(props = {}) {
    const propsData = {
      users: [],
      rootPath: TEST_HOST,
      ...props,
    };

    wrapper = mount(UncollapsedAssigneeList, {
      sync: false,
      propsData,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findMoreButton = () => wrapper.find('.user-list-more button');

  describe('One assignee/user', () => {
    let user;

    beforeEach(() => {
      user = userDataMock();

      createComponent({
        users: [user],
      });
    });

    it('only has one user', () => {
      expect(wrapper.findAll(AssigneeAvatarLink).length).toBe(1);
    });

    it('calls the AssigneeAvatarLink with the proper props', () => {
      expect(wrapper.find(AssigneeAvatarLink).exists()).toBe(true);
      expect(wrapper.find(AssigneeAvatarLink).props().tooltipPlacement).toEqual('left');
    });

    it('Shows one user with avatar, username and author name', () => {
      expect(wrapper.text()).toContain(user.name);
      expect(wrapper.text()).toContain(`@${user.username}`);
    });
  });

  describe('Two or more assignees/users', () => {
    beforeEach(() => {
      createComponent({
        users: UsersMockHelper.createNumberRandomUsers(3),
      });
    });

    it('more than one user', () => {
      expect(wrapper.findAll(AssigneeAvatarLink).length).toBe(3);
    });

    it('shows the "show-less" assignees label', done => {
      const users = UsersMockHelper.createNumberRandomUsers(6);

      createComponent({
        users,
      });

      expect(wrapper.vm.$el.querySelectorAll('.user-item').length).toEqual(DEFAULT_RENDER_COUNT);

      expect(wrapper.vm.$el.querySelector('.user-list-more')).not.toBe(null);
      const usersLabelExpectation = users.length - DEFAULT_RENDER_COUNT;

      expect(wrapper.vm.$el.querySelector('.user-list-more .btn-link').innerText.trim()).not.toBe(
        `+${usersLabelExpectation} more`,
      );
      wrapper.vm.toggleShowLess();
      Vue.nextTick(() => {
        expect(wrapper.vm.$el.querySelector('.user-list-more .btn-link').innerText.trim()).toBe(
          '- show less',
        );
        done();
      });
    });

    it('shows the "show-less" when "n+ more " label is clicked', done => {
      createComponent({
        users: UsersMockHelper.createNumberRandomUsers(6),
      });

      wrapper.vm.$el.querySelector('.user-list-more .btn-link').click();
      Vue.nextTick(() => {
        expect(wrapper.vm.$el.querySelector('.user-list-more .btn-link').innerText.trim()).toBe(
          '- show less',
        );
        done();
      });
    });

    it('does not show n+ more label when less than render count', () => {
      expect(findMoreButton().exists()).toBe(false);
    });
  });

  describe('n+ more label', () => {
    beforeEach(() => {
      createComponent({
        users: UsersMockHelper.createNumberRandomUsers(DEFAULT_RENDER_COUNT + 1),
      });
    });

    it('shows "+1 more" label', () => {
      expect(findMoreButton().text()).toBe('+ 1 more');
      expect(wrapper.findAll(AssigneeAvatarLink).length).toBe(DEFAULT_RENDER_COUNT);
    });

    it('shows "show less" label', done => {
      findMoreButton().trigger('click');

      Vue.nextTick(() => {
        expect(findMoreButton().text()).toBe('- show less');
        expect(wrapper.findAll(AssigneeAvatarLink).length).toBe(DEFAULT_RENDER_COUNT + 1);
        done();
      });
    });
  });
});
