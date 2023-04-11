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
  const findAllReviewerApprovalIcons = () => wrapper.findAll('[data-testid="approved"]');
  const findAllReviewedNotApprovedIcons = () =>
    wrapper.findAll('[data-testid="reviewed-not-approved"]');
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
    const user3 = {
      ...user,
      id: 3,
      name: 'lizabeth-wilderman',
      username: 'lizabeth-wilderman',
      mergeRequestInteraction: {
        ...user.mergeRequestInteraction,
        approved: false,
        reviewed: true,
      },
    };

    beforeEach(() => {
      createComponent({
        users: [user, user2, user3],
      });
    });

    it('has three users', () => {
      expect(findAllReviewerAvatarLinks()).toHaveLength(3);
    });

    it('shows all users with avatar, and author name', () => {
      expect(wrapper.text()).toContain(user.name);
      expect(wrapper.text()).toContain(user2.name);
      expect(wrapper.text()).toContain(user3.name);
    });

    it('renders approval icon', () => {
      expect(findAllReviewerApprovalIcons()).toHaveLength(1);
    });

    it('shows that hello-world approved', () => {
      const icon = findAllReviewerApprovalIcons().at(0);

      expect(icon.attributes('title')).toBe('Approved by @hello-world');
    });

    it('shows that lizabeth-wilderman reviewed but did not approve', () => {
      const icon = findAllReviewedNotApprovedIcons().at(1);

      expect(icon.attributes('title')).toBe('Reviewed by @lizabeth-wilderman but not yet approved');
    });

    it('renders re-request loading icon', async () => {
      await findAllRerequestButtons().at(1).vm.$emit('click');

      const allRerequestButtons = findAllRerequestButtons();

      expect(allRerequestButtons).toHaveLength(3);
      expect(allRerequestButtons.at(1).props('loading')).toBe(true);
    });
  });
});
