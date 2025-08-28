import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserAvatar from '~/merge_request_dashboard/components/user_avatar.vue';

let wrapper;

function createComponent() {
  wrapper = shallowMountExtended(UserAvatar, {
    propsData: {
      user: {
        id: 'gid://gitlab/user/2',
        webUrl: '/root',
        name: 'Admin',
        avatarUrl: '/root',
        mergeRequestInteraction: {
          reviewState: 'REQUESTED_CHANGES',
        },
      },
    },
  });
}

describe('Merge request dashboard user avatar component', () => {
  const findReviewStateIcon = () => wrapper.findByTestId('review-state-icon');

  it('renders review state icon', () => {
    createComponent();

    expect(findReviewStateIcon().html()).toMatchSnapshot();
  });
});
