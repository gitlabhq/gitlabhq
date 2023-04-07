import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import ReviewerAvatarLink from '~/sidebar/components/reviewers/reviewer_avatar_link.vue';
import UncollapsedReviewerList from '~/sidebar/components/reviewers/uncollapsed_reviewer_list.vue';

const userDataMock = () => ({
  id: 1,
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
  },
});

describe('UncollapsedReviewerList component', () => {
  let wrapper;

  const findAllRerequestButtons = () => wrapper.findAll('[data-testid="re-request-button"]');
  const findAllRerequestSuccessIcons = () => wrapper.findAll('[data-testid="re-request-success"]');
  const findAllReviewerApprovalIcons = () => wrapper.findAll('[data-testid="re-approved"]');
  const findAllReviewerAvatarLinks = () => wrapper.findAllComponents(ReviewerAvatarLink);

  function createComponent(props = {}, glFeatures = {}) {
    const propsData = {
      users: [],
      rootPath: TEST_HOST,
      ...props,
    };

    wrapper = shallowMount(UncollapsedReviewerList, {
      propsData,
      provide: {
        glFeatures,
      },
    });
  }

  const callRerequestCallback = async () => {
    const payload = wrapper.emitted('request-review')[0][0];
    // Call payload which is normally called by a parent component
    payload.callback(payload.userId, true);
    await nextTick();
  };

  describe('single reviewer', () => {
    const user = userDataMock();

    beforeEach(() => {
      createComponent({
        users: [user],
      });
    });

    it('only has one user', () => {
      expect(findAllReviewerAvatarLinks()).toHaveLength(1);
    });

    it('shows one user with avatar, and author name', () => {
      expect(wrapper.text()).toBe(user.name);
    });

    it('renders re-request loading icon', async () => {
      await findAllRerequestButtons().at(0).vm.$emit('click');

      expect(findAllRerequestButtons().at(0).props('loading')).toBe(true);
    });

    it('renders re-request success icon', async () => {
      await findAllRerequestButtons().at(0).vm.$emit('click');
      await callRerequestCallback();

      expect(findAllRerequestSuccessIcons().at(0).exists()).toBe(true);
    });
  });

  describe('multiple reviewers', () => {
    const user = userDataMock();
    const user2 = {
      ...user,
      id: 2,
      name: 'nonrooty-nonrootersen',
      username: 'hello-world',
      mergeRequestInteraction: {
        ...user.mergeRequestInteraction,
        approved: true,
      },
    };

    beforeEach(() => {
      createComponent({
        users: [user, user2],
      });
    });

    it('has both users', () => {
      expect(findAllReviewerAvatarLinks()).toHaveLength(2);
    });

    it('shows both users with avatar, and author name', () => {
      expect(wrapper.text()).toContain(user.name);
      expect(wrapper.text()).toContain(user2.name);
    });

    it('renders approval icon', () => {
      expect(findAllReviewerApprovalIcons()).toHaveLength(1);
    });

    it('shows that hello-world approved', () => {
      const icon = findAllReviewerApprovalIcons().at(0);

      expect(icon.attributes('title')).toBe('Approved by @hello-world');
    });

    it('renders re-request loading icon', async () => {
      await findAllRerequestButtons().at(1).vm.$emit('click');

      const allRerequestButtons = findAllRerequestButtons();

      expect(allRerequestButtons).toHaveLength(2);
      expect(allRerequestButtons.at(1).props('loading')).toBe(true);
    });

    it('renders re-request success icon', async () => {
      await findAllRerequestButtons().at(1).vm.$emit('click');
      await callRerequestCallback();

      expect(findAllRerequestButtons()).toHaveLength(1);
      expect(findAllRerequestSuccessIcons()).toHaveLength(1);
    });
  });
});
