import { shallowMount } from '@vue/test-utils';
import { GlAvatar, GlIcon } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import AssigneeAvatar from '~/sidebar/components/assignees/assignee_avatar.vue';
import userDataMock from '../../user_data_mock';

const TEST_AVATAR = `${TEST_HOST}/avatar.png`;
const TEST_DEFAULT_AVATAR_URL = `${TEST_HOST}/default/avatar/url.png`;

describe('AssigneeAvatar', () => {
  let wrapper;

  function createComponent(props = {}) {
    const propsData = {
      user: userDataMock(),
      imgSize: 24,
      issuableType: 'merge_request',
      ...props,
    };

    wrapper = shallowMount(AssigneeAvatar, {
      propsData,
    });
  }

  beforeEach(() => {
    window.gon = { default_avatar_url: TEST_DEFAULT_AVATAR_URL };
  });

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findIcon = () => wrapper.findComponent(GlIcon);

  it('does not show warning icon if assignee can merge', () => {
    createComponent();

    expect(findIcon().exists()).toBe(false);
  });

  it('shows warning icon if assignee cannot merge', () => {
    createComponent({
      user: {
        can_merge: false,
      },
    });

    expect(findIcon().exists()).toBe(true);
  });

  it('does not show warning icon for issuableType = "issue"', () => {
    createComponent({
      issuableType: 'issue',
    });

    expect(findIcon().exists()).toBe(false);
  });

  it.each`
    avatar         | avatar_url     | expected                   | desc
    ${TEST_AVATAR} | ${null}        | ${TEST_AVATAR}             | ${'with avatar'}
    ${null}        | ${TEST_AVATAR} | ${TEST_AVATAR}             | ${'with avatar_url'}
    ${null}        | ${null}        | ${TEST_DEFAULT_AVATAR_URL} | ${'with no avatar'}
  `('$desc', ({ avatar, avatar_url, expected }) => {
    createComponent({
      user: {
        avatar,
        avatar_url,
      },
    });

    expect(findAvatar().props('src')).toEqual(expected);
  });
});
