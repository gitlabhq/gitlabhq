import { shallowMount } from '@vue/test-utils';
import { APPROVED_MESSAGE } from '~/vue_merge_request_widget/components/approvals/messages';
import ApprovalsSummary from '~/vue_merge_request_widget/components/approvals/approvals_summary.vue';
import { toNounSeriesText } from '~/lib/utils/grammar';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';

const testApprovers = () => Array.from({ length: 5 }, (_, i) => i).map(id => ({ id }));
const testRulesLeft = () => ['Lorem', 'Ipsum', 'dolar & sit'];
const TEST_APPROVALS_LEFT = 3;

describe('MRWidget approvals summary', () => {
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
  });

  describe('when approved', () => {
    beforeEach(() => {
      createComponent({
        approved: true,
      });
    });

    it('shows approved message', () => {
      expect(wrapper.text()).toContain(APPROVED_MESSAGE);
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
  });

  describe('when not approved', () => {
    beforeEach(() => {
      createComponent();
    });

    it('render message', () => {
      const names = toNounSeriesText(testRulesLeft());

      expect(wrapper.text()).toContain(
        `Requires ${TEST_APPROVALS_LEFT} more approvals from ${names}.`,
      );
    });
  });

  describe('when no rulesLeft', () => {
    beforeEach(() => {
      createComponent({
        rulesLeft: [],
      });
    });

    it('renders message', () => {
      expect(wrapper.text()).toContain(`Requires ${TEST_APPROVALS_LEFT} more approvals.`);
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
