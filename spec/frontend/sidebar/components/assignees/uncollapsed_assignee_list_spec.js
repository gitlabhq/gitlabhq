import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import AssigneeAvatarLink from '~/sidebar/components/assignees/assignee_avatar_link.vue';
import UncollapsedAssigneeList from '~/sidebar/components/assignees/uncollapsed_assignee_list.vue';
import userDataMock from '../../user_data_mock';

const DEFAULT_RENDER_COUNT = 5;

describe('UncollapsedAssigneeList component', () => {
  let wrapper;

  function createComponent(props = {}, glFeatures = {}) {
    const propsData = {
      users: [],
      rootPath: TEST_HOST,
      ...props,
    };

    wrapper = mount(UncollapsedAssigneeList, {
      propsData,
      provide: { glFeatures },
    });
  }

  const findMoreButton = () => wrapper.find('[data-testid="user-list-more-button"]');

  describe('One assignee/user', () => {
    let user;

    beforeEach(() => {
      user = userDataMock();

      createComponent({
        users: [user],
      });
    });

    it('only has one user', () => {
      expect(wrapper.findAllComponents(AssigneeAvatarLink).length).toBe(1);
    });

    it('calls the AssigneeAvatarLink with the proper props', () => {
      expect(wrapper.findComponent(AssigneeAvatarLink).exists()).toBe(true);
    });

    it('Shows one user with avatar, username and author name', () => {
      expect(wrapper.text()).toContain(user.name);
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
        expect(wrapper.findAllComponents(AssigneeAvatarLink).length).toBe(DEFAULT_RENDER_COUNT);
      });

      describe('when more button is clicked', () => {
        beforeEach(async () => {
          findMoreButton().trigger('click');

          await nextTick();
        });

        it('shows "show less" label', () => {
          expect(findMoreButton().text()).toBe('- show less');
        });

        it('shows all users', () => {
          expect(wrapper.findAllComponents(AssigneeAvatarLink).length).toBe(
            DEFAULT_RENDER_COUNT + 1,
          );
        });
      });
    });
  });

  describe('merge requests', () => {
    it.each`
      numberOfUsers
      ${1}
      ${5}
    `('displays as a vertical list for $numberOfUsers of users', ({ numberOfUsers }) => {
      createComponent(
        {
          users: UsersMockHelper.createNumberRandomUsers(numberOfUsers),
          issuableType: 'merge_request',
        },
        { mrAttentionRequests: true },
      );

      expect(wrapper.findAll('[data-testid="username"]').length).toBe(numberOfUsers);
    });
  });
});
