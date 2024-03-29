import { mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import Reviewer from '~/sidebar/components/reviewers/reviewers.vue';

const usersMock = (id = 1) => ({
  id,
  name: 'Root',
  state: 'active',
  username: 'root',
  webUrl: `${TEST_HOST}/root`,
  avatarUrl: `${TEST_HOST}/avatar/root.png`,
  mergeRequestInteraction: {
    canMerge: true,
    canUpdate: true,
    reviewed: true,
    approved: false,
    reviewState: 'UNREVIEWED',
  },
});

describe('Reviewer component', () => {
  const getDefaultProps = () => ({
    rootPath: 'http://localhost:3000',
    users: [],
    editable: false,
  });
  let wrapper;

  const createWrapper = (propsData = getDefaultProps()) => {
    wrapper = mount(Reviewer, {
      propsData,
    });
  };

  describe('Two or more reviewers/users', () => {
    it('Shows two reviewers', () => {
      const users = [usersMock(), usersMock(2)];
      createWrapper({
        ...getDefaultProps(),
        users,
        editable: true,
      });

      expect(wrapper.findAll('[data-testid="reviewer"]').length).toBe(users.length);
    });

    it('shows sorted reviewer where "can merge" users are sorted first', () => {
      const users = [usersMock(), usersMock(2), usersMock(3)];
      users[0].mergeRequestInteraction.canMerge = false;
      users[1].mergeRequestInteraction.canMerge = false;
      users[2].mergeRequestInteraction.canMerge = true;

      createWrapper({
        ...getDefaultProps(),
        users,
        editable: true,
      });

      expect(wrapper.vm.sortedReviewers[0].mergeRequestInteraction.canMerge).toBe(true);
    });

    it('passes the sorted reviewers to the uncollapsed-reviewer-list', () => {
      const users = [usersMock(), usersMock(2), usersMock(3)];
      users[0].mergeRequestInteraction.canMerge = false;
      users[1].mergeRequestInteraction.canMerge = false;
      users[2].mergeRequestInteraction.canMerge = true;

      createWrapper({
        ...getDefaultProps(),
        users,
      });

      const userItems = wrapper.findAll('[data-testid="reviewer"]');

      expect(userItems.length).toBe(3);
    });
  });
});
