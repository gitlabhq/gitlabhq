import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import ReviewerAvatarLink from '~/sidebar/components/reviewers/reviewer_avatar_link.vue';
import UncollapsedReviewerList from '~/sidebar/components/reviewers/uncollapsed_reviewer_list.vue';

const userDataMock = ({ approved = true, reviewState = 'UNREVIEWED' } = {}) => ({
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
    approved,
    reviewState,
  },
});

describe('UncollapsedReviewerList component', () => {
  let wrapper;

  const findAllRerequestButtons = () => wrapper.findAll('[data-testid="re-request-button"]');
  const findAllReviewerApprovalIcons = () => wrapper.findAll('[name="check-circle"]');
  const findAllReviewerAvatarLinks = () => wrapper.findAllComponents(ReviewerAvatarLink);

  const hasApprovalIconAnimation = () =>
    wrapper
      .findAll('[data-testid="reviewer-state-icon-parent"]')
      .at(0)
      .classes('merge-request-approved-icon');

  function createComponent(props = {}) {
    const propsData = {
      users: [],
      rootPath: TEST_HOST,
      canRerequest: true,
      ...props,
    };

    wrapper = shallowMount(UncollapsedReviewerList, {
      propsData,
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

  describe('when reviewer status is unapproved', () => {
    beforeEach(() => {
      const user = userDataMock();

      createComponent({
        users: [
          {
            ...user,
            id: 2,
            name: 'nonrooty-nonrootersen',
            username: 'hello-world',
            mergeRequestInteraction: {
              ...user.mergeRequestInteraction,
              approved: false,
              reviewState: 'UNAPPROVED',
            },
          },
        ],
      });
    });

    it('renders re-request review button', () => {
      expect(findAllRerequestButtons().exists()).toBe(true);
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
      expect(findAllReviewerApprovalIcons()).toHaveLength(2);
    });

    it('shows that hello-world approved', () => {
      const icon = findAllReviewerApprovalIcons().at(0);

      expect(icon.attributes('arialabel')).toBe('Reviewer approved changes');
    });

    it('renders re-request loading icon', async () => {
      await findAllRerequestButtons().at(1).vm.$emit('click');

      const allRerequestButtons = findAllRerequestButtons();

      expect(allRerequestButtons).toHaveLength(2);
      expect(allRerequestButtons.at(1).props('loading')).toBe(true);
    });
  });

  describe('when updating reviewers list', () => {
    it('does not animate icon on initial page load', () => {
      const user = userDataMock({ approved: true });
      createComponent({ users: [user] });

      expect(hasApprovalIconAnimation()).toBe(false);
    });

    it('does not animate icon when adding a new reviewer', async () => {
      const user = userDataMock({ approved: true });
      const anotherUser = { ...user, id: 2 };
      createComponent({ users: [user] });

      await wrapper.setProps({ users: [user, anotherUser] });

      expect(
        findAllReviewerApprovalIcons().wrappers.every((w) =>
          w.classes('merge-request-approved-icon'),
        ),
      ).toBe(false);
    });

    it('removes animation CSS class after 1500ms', async () => {
      const previousUserState = userDataMock({ approved: false });
      const currentUserState = userDataMock({ approved: true });

      createComponent({
        users: [previousUserState],
      });

      await wrapper.setProps({
        users: [currentUserState],
      });

      expect(hasApprovalIconAnimation()).toBe(true);

      jest.advanceTimersByTime(1500);
      await nextTick();

      expect(findAllReviewerApprovalIcons().at(0).classes('merge-request-approved-icon')).toBe(
        false,
      );
    });

    describe('when reviewer was present in the list', () => {
      it.each`
        previousApprovalState | currentApprovalState | shouldAnimate
        ${false}              | ${true}              | ${true}
        ${true}               | ${true}              | ${false}
      `(
        'when approval state changes from $previousApprovalState to $currentApprovalState',
        async ({ previousApprovalState, currentApprovalState, shouldAnimate }) => {
          const previousUserState = userDataMock({ approved: previousApprovalState });
          const currentUserState = userDataMock({ approved: currentApprovalState });

          createComponent({
            users: [previousUserState],
          });

          await wrapper.setProps({
            users: [currentUserState],
          });

          expect(hasApprovalIconAnimation()).toBe(shouldAnimate);
        },
      );
    });
  });

  describe('reviewer state icons', () => {
    it.each`
      reviewState            | approved | icon               | iconClass
      ${'UNREVIEWED'}        | ${false} | ${'dash-circle'}   | ${'gl-fill-icon-default'}
      ${'REVIEWED'}          | ${true}  | ${'check-circle'}  | ${'gl-fill-icon-success'}
      ${'REVIEWED'}          | ${false} | ${'comment-lines'} | ${'gl-fill-icon-info'}
      ${'REQUESTED_CHANGES'} | ${false} | ${'error'}         | ${'gl-fill-icon-danger'}
    `(
      'renders $icon for reviewState:$reviewState and approved:$approved',
      ({ reviewState, approved, icon, iconClass }) => {
        const user = userDataMock({ approved, reviewState });

        createComponent({
          users: [user],
        });

        expect(wrapper.find('[data-testid="reviewer-state-icon"]').props('name')).toBe(icon);
        expect(wrapper.find('[data-testid="reviewer-state-icon"]').classes()).toEqual([iconClass]);
      },
    );
  });

  describe('re-requesting review', () => {
    it.each`
      description          | reviewState     | canRerequest | expectedButtonVisibility
      ${'should show'}     | ${'UNAPPROVED'} | ${true}      | ${true}
      ${'should not show'} | ${'UNAPPROVED'} | ${false}     | ${false}
      ${'should show'}     | ${'UNREVIEWED'} | ${true}      | ${true}
      ${'should not show'} | ${'UNREVIEWED'} | ${false}     | ${false}
    `(
      '$description re-request button for users with state:$reviewState when canRerequest:$canRerequest',
      ({ reviewState, canRerequest, expectedButtonVisibility }) => {
        createComponent({
          users: [userDataMock({ reviewState })],
          canRerequest,
        });
        expect(findAllRerequestButtons().exists()).toBe(expectedButtonVisibility);
      },
    );
  });
});
