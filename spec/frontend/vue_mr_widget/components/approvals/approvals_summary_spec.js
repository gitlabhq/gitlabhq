import { shallowMount } from '@vue/test-utils';
import { toNounSeriesText } from '~/lib/utils/grammar';
import ApprovalsSummary from '~/vue_merge_request_widget/components/approvals/approvals_summary.vue';
import {
  APPROVED_BY_OTHERS,
  APPROVED_BY_YOU,
  APPROVED_BY_YOU_AND_OTHERS,
} from '~/vue_merge_request_widget/components/approvals/messages';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';

const exampleUserId = 1;
const testApprovers = () => Array.from({ length: 5 }, (_, i) => i).map((id) => ({ id }));
const testRulesLeft = () => ['Lorem', 'Ipsum', 'dolar & sit'];
const TEST_APPROVALS_LEFT = 3;

describe('MRWidget approvals summary', () => {
  const originalUserId = gon.current_user_id;
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ApprovalsSummary, {
      propsData: {
        approved: false,
        approvers: testApprovers(),
        approvalsLeft: TEST_APPROVALS_LEFT,
        rulesLeft: testRulesLeft(),
        ...props,
      },
    });
  };

  const findAvatars = () => wrapper.find(UserAvatarList);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    gon.current_user_id = originalUserId;
  });

  describe('when approved', () => {
    beforeEach(() => {
      createComponent({
        approved: true,
      });
    });

    it('shows approved message', () => {
      expect(wrapper.text()).toContain(APPROVED_BY_OTHERS);
    });

    it('renders avatar list for approvers', () => {
      const avatars = findAvatars();

      expect(avatars.exists()).toBe(true);
      expect(avatars.props()).toEqual(
        expect.objectContaining({
          items: testApprovers(),
        }),
      );
    });

    describe('by the current user', () => {
      beforeEach(() => {
        gon.current_user_id = exampleUserId;
        createComponent({
          approvers: [{ id: exampleUserId }],
          approved: true,
        });
      });

      it('shows "Approved by you" message', () => {
        expect(wrapper.text()).toContain(APPROVED_BY_YOU);
      });
    });

    describe('by the current user and others', () => {
      beforeEach(() => {
        gon.current_user_id = exampleUserId;
        createComponent({
          approvers: [{ id: exampleUserId }, { id: exampleUserId + 1 }],
          approved: true,
        });
      });

      it('shows "Approved by you and others" message', () => {
        expect(wrapper.text()).toContain(APPROVED_BY_YOU_AND_OTHERS);
      });
    });

    describe('by other users than the current user', () => {
      beforeEach(() => {
        gon.current_user_id = exampleUserId;
        createComponent({
          approvers: [{ id: exampleUserId + 1 }],
          approved: true,
        });
      });

      it('shows "Approved by others" message', () => {
        expect(wrapper.text()).toContain(APPROVED_BY_OTHERS);
      });
    });
  });

  describe('when not approved', () => {
    beforeEach(() => {
      createComponent();
    });

    it('render message', () => {
      const names = toNounSeriesText(testRulesLeft());

      expect(wrapper.text()).toContain(`Requires ${TEST_APPROVALS_LEFT} approvals from ${names}.`);
    });
  });

  describe('when no rulesLeft', () => {
    beforeEach(() => {
      createComponent({
        rulesLeft: [],
      });
    });

    it('renders message', () => {
      expect(wrapper.text()).toContain(
        `Requires ${TEST_APPROVALS_LEFT} approvals from eligible users`,
      );
    });
  });

  describe('when no approvers', () => {
    beforeEach(() => {
      createComponent({
        approvers: [],
      });
    });

    it('does not render avatar list', () => {
      expect(wrapper.find(UserAvatarList).exists()).toBe(false);
    });
  });
});
