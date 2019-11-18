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
      attachToDocument: true,
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

  describe('n+ more label', () => {
    describe('when users count is rendered users', () => {
      beforeEach(() => {
        createComponent({
          users: UsersMockHelper.createNumberRandomUsers(DEFAULT_RENDER_COUNT),
        });
      });

      it('does not show more label', () => {
        expect(findMoreButton().exists()).toBe(false);
      });
    });

    describe('when more than rendered users', () => {
      beforeEach(() => {
        createComponent({
          users: UsersMockHelper.createNumberRandomUsers(DEFAULT_RENDER_COUNT + 1),
        });
      });

      it('shows "+1 more" label', () => {
        expect(findMoreButton().text()).toBe('+ 1 more');
      });

      it('shows truncated users', () => {
        expect(wrapper.findAll(AssigneeAvatarLink).length).toBe(DEFAULT_RENDER_COUNT);
      });

      describe('when more button is clicked', () => {
        beforeEach(() => {
          findMoreButton().trigger('click');

          return wrapper.vm.$nextTick();
        });

        it('shows "show less" label', () => {
          expect(findMoreButton().text()).toBe('- show less');
        });

        it('shows all users', () => {
          expect(wrapper.findAll(AssigneeAvatarLink).length).toBe(DEFAULT_RENDER_COUNT + 1);
        });
      });
    });
  });
});
