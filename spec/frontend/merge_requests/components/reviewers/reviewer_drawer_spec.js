import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlDrawer } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import ReviewerDrawer from '~/merge_requests/components/reviewers/reviewer_drawer.vue';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import getMergeRequestReviewers from '~/sidebar/queries/get_merge_request_reviewers.query.graphql';
import userPermissionsQuery from '~/merge_requests/components/reviewers/queries/user_permissions.query.graphql';

jest.mock('~/lib/utils/dom_utils', () => ({ getContentWrapperHeight: jest.fn() }));

let wrapper;

Vue.use(VueApollo);

function createComponent(propsData = {}) {
  const apolloProvider = createMockApollo([
    [getMergeRequestReviewers, jest.fn().mockResolvedValue({ data: { workspace: null } })],
    [userPermissionsQuery, jest.fn().mockResolvedValue({ data: { project: null } })],
  ]);

  wrapper = shallowMount(ReviewerDrawer, {
    apolloProvider,
    propsData,
    provide: {
      projectPath: 'gitlab-org/gitlab',
      issuableId: '1',
      issuableIid: '1',
      multipleApprovalRulesAvailable: false,
    },
  });
}

const findDrawer = () => wrapper.findComponent(GlDrawer);

describe('Reviewer drawer component', () => {
  it('renders the drawer', () => {
    createComponent({ open: true });

    expect(findDrawer().exists()).toBe(true);
    expect(findDrawer().props()).toMatchObject(
      expect.objectContaining({ open: true, zIndex: 252 }),
    );
  });

  describe('heeader height', () => {
    it.each`
      height   | open
      ${'0'}   | ${false}
      ${'200'} | ${true}
    `('sets height header-height prop to $height when open is $open', ({ height, open }) => {
      getContentWrapperHeight.mockReturnValue('200');

      createComponent({ open });

      expect(findDrawer().props('headerHeight')).toBe(height);
    });
  });
});
