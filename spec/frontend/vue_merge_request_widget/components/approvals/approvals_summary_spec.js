import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import approvedByMultipleUsers from 'test_fixtures/graphql/merge_requests/approvals/approvals.query.graphql_multiple_users.json';
import noApprovalsResponse from 'test_fixtures/graphql/merge_requests/approvals/approvals.query.graphql_no_approvals.json';
import approvedByCurrentUser from 'test_fixtures/graphql/merge_requests/approvals/approvals.query.graphql.json';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import ApprovalsSummary from '~/vue_merge_request_widget/components/approvals/approvals_summary.vue';
import {
  APPROVED_BY_OTHERS,
  APPROVED_BY_YOU,
  APPROVED_BY_YOU_AND_OTHERS,
} from '~/vue_merge_request_widget/components/approvals/messages';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';

Vue.use(VueApollo);

describe('MRWidget approvals summary', () => {
  let wrapper;

  const createComponent = (data = approvedByCurrentUser) => {
    wrapper = mount(ApprovalsSummary, {
      propsData: {
        approvalState: data.data.project.mergeRequest,
      },
    });
  };

  const findAvatars = () => wrapper.findComponent(UserAvatarList);

  describe('when approved', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('shows approved message', () => {
      expect(wrapper.text()).toContain(APPROVED_BY_OTHERS);
    });

    it('renders avatar list for approvers', () => {
      const avatars = findAvatars();

      expect(avatars.exists()).toBe(true);
      expect(avatars.props()).toEqual(
        expect.objectContaining({
          items: approvedByCurrentUser.data.project.mergeRequest.approvedBy.nodes,
        }),
      );
    });

    describe('by the current user', () => {
      beforeEach(async () => {
        gon.current_user_id = getIdFromGraphQLId(
          approvedByCurrentUser.data.project.mergeRequest.approvedBy.nodes[0].id,
        );
        createComponent();

        await waitForPromises();
      });

      it('shows "Approved by you" message', () => {
        expect(wrapper.text()).toContain(APPROVED_BY_YOU);
      });
    });

    describe('by the current user and others', () => {
      beforeEach(async () => {
        gon.current_user_id = getIdFromGraphQLId(
          approvedByMultipleUsers.data.project.mergeRequest.approvedBy.nodes[0].id,
        );
        createComponent(approvedByMultipleUsers);

        await waitForPromises();
      });

      it('shows "Approved by you and others" message', () => {
        expect(wrapper.text()).toContain(APPROVED_BY_YOU_AND_OTHERS);
      });
    });

    describe('by other users than the current user', () => {
      beforeEach(async () => {
        createComponent(approvedByMultipleUsers);

        await waitForPromises();
      });

      it('shows "Approved by others" message', () => {
        expect(wrapper.text()).toContain(APPROVED_BY_OTHERS);
      });
    });
  });

  describe('when no approvers', () => {
    beforeEach(async () => {
      createComponent(noApprovalsResponse);

      await waitForPromises();
    });

    it('does not render avatar list', () => {
      expect(wrapper.findComponent(UserAvatarList).exists()).toBe(false);
    });
  });

  describe('user avatars list layout', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not add top padding initially', () => {
      const avatarsList = findAvatars();

      expect(avatarsList.classes()).not.toContain('gl-pt-1');
    });

    it('adds some top padding when the list is expanded', async () => {
      const avatarsList = findAvatars();
      await avatarsList.vm.$emit('expanded');

      expect(avatarsList.classes()).toContain('gl-pt-1');
    });

    it('removes the top padding when the list collapsed', async () => {
      const avatarsList = findAvatars();
      await avatarsList.vm.$emit('expanded');
      await avatarsList.vm.$emit('collapsed');

      expect(avatarsList.classes()).not.toContain('gl-pt-1');
    });
  });
});
