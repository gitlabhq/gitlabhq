import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import ReviewerAvatar from '~/sidebar/components/reviewers/reviewer_avatar.vue';
import ReviewerAvatarLink from '~/sidebar/components/reviewers/reviewer_avatar_link.vue';
import userDataMock from '../../user_data_mock';

const TEST_ISSUABLE_TYPE = 'merge_request';

describe('ReviewerAvatarLink component', () => {
  const mockUserData = {
    ...userDataMock(),
    webUrl: `${TEST_HOST}/root`,
  };
  let wrapper;

  function createComponent(props = {}) {
    const propsData = {
      user: mockUserData,
      rootPath: TEST_HOST,
      issuableType: TEST_ISSUABLE_TYPE,
      ...props,
    };

    wrapper = shallowMount(ReviewerAvatarLink, {
      propsData,
    });
  }

  const findUserLink = () => wrapper.findComponent(GlLink);

  it('has the root url present in the assigneeUrl method', () => {
    createComponent();

    expect(wrapper.attributes().href).toEqual(mockUserData.web_url);
  });

  it('renders reviewer avatar', () => {
    createComponent();

    expect(wrapper.findComponent(ReviewerAvatar).props()).toMatchObject({
      imgSize: 24,
      user: mockUserData,
    });
  });

  it('passes the correct user id, username, cannotMerge, and CSS class for popover support', () => {
    const { id, username } = mockUserData;

    createComponent({
      tooltipHasName: true,
      issuableType: 'merge_request',
      user: mockUserData,
    });

    const userLink = findUserLink();

    expect(userLink.attributes()).toMatchObject({
      'data-user-id': `${id}`,
      'data-username': username,
      'data-cannot-merge': 'true',
      'data-placement': 'left',
    });
    expect(userLink.classes()).toContain('js-user-link');
  });
});
