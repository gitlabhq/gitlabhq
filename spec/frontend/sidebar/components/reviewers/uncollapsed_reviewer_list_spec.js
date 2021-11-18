import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import AttentionRequestedToggle from '~/sidebar/components/attention_requested_toggle.vue';
import ReviewerAvatarLink from '~/sidebar/components/reviewers/reviewer_avatar_link.vue';
import UncollapsedReviewerList from '~/sidebar/components/reviewers/uncollapsed_reviewer_list.vue';
import userDataMock from '../../user_data_mock';

describe('UncollapsedReviewerList component', () => {
  let wrapper;

  const reviewerApprovalIcons = () => wrapper.findAll('[data-testid="re-approved"]');

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

  afterEach(() => {
    wrapper.destroy();
  });

  describe('single reviewer', () => {
    const user = userDataMock();

    beforeEach(() => {
      createComponent({
        users: [user],
      });
    });

    it('only has one user', () => {
      expect(wrapper.findAll(ReviewerAvatarLink).length).toBe(1);
    });

    it('shows one user with avatar, username and author name', () => {
      expect(wrapper.text()).toContain(user.name);
      expect(wrapper.text()).toContain(`@root`);
    });

    it('renders re-request loading icon', async () => {
      await wrapper.setData({ loadingStates: { 1: 'loading' } });

      expect(wrapper.find('[data-testid="re-request-button"]').props('loading')).toBe(true);
    });

    it('renders re-request success icon', async () => {
      await wrapper.setData({ loadingStates: { 1: 'success' } });

      expect(wrapper.find('[data-testid="re-request-success"]').exists()).toBe(true);
    });
  });

  describe('multiple reviewers', () => {
    const user = userDataMock();
    const user2 = {
      ...user,
      id: 2,
      name: 'nonrooty-nonrootersen',
      username: 'hello-world',
      approved: true,
    };

    beforeEach(() => {
      createComponent({
        users: [user, user2],
      });
    });

    it('has both users', () => {
      expect(wrapper.findAll(ReviewerAvatarLink).length).toBe(2);
    });

    it('shows both users with avatar, username and author name', () => {
      expect(wrapper.text()).toContain(user.name);
      expect(wrapper.text()).toContain(`@root`);
      expect(wrapper.text()).toContain(user2.name);
      expect(wrapper.text()).toContain(`@hello-world`);
    });

    it('renders approval icon', () => {
      expect(reviewerApprovalIcons().length).toBe(1);
    });

    it('shows that hello-world approved', () => {
      const icon = reviewerApprovalIcons().at(0);

      expect(icon.attributes('title')).toEqual('Approved by @hello-world');
    });

    it('renders re-request loading icon', async () => {
      await wrapper.setData({ loadingStates: { 2: 'loading' } });

      expect(wrapper.findAll('[data-testid="re-request-button"]').length).toBe(2);
      expect(wrapper.findAll('[data-testid="re-request-button"]').at(1).props('loading')).toBe(
        true,
      );
    });

    it('renders re-request success icon', async () => {
      await wrapper.setData({ loadingStates: { 2: 'success' } });

      expect(wrapper.findAll('[data-testid="re-request-button"]').length).toBe(1);
      expect(wrapper.findAll('[data-testid="re-request-success"]').length).toBe(1);
      expect(wrapper.find('[data-testid="re-request-success"]').exists()).toBe(true);
    });
  });

  it('hides re-request review button when attentionRequired feature flag is enabled', () => {
    createComponent({ users: [userDataMock()] }, { mrAttentionRequests: true });

    expect(wrapper.findAll('[data-testid="re-request-button"]').length).toBe(0);
  });

  it('emits toggle-attention-requested', () => {
    createComponent({ users: [userDataMock()] }, { mrAttentionRequests: true });

    wrapper.find(AttentionRequestedToggle).vm.$emit('toggle-attention-requested', 'data');

    expect(wrapper.emitted('toggle-attention-requested')[0]).toEqual(['data']);
  });
});
