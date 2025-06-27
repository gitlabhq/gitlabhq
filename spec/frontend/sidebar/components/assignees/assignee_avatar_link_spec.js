import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import AssigneeAvatar from '~/sidebar/components/assignees/assignee_avatar.vue';
import AssigneeAvatarLink from '~/sidebar/components/assignees/assignee_avatar_link.vue';
import userDataMock from '../../user_data_mock';

const TEST_ISSUABLE_TYPE = 'issue';

describe('AssigneeAvatarLink component', () => {
  let wrapper;

  function createComponent(props = {}) {
    const propsData = {
      user: userDataMock(),
      issuableType: TEST_ISSUABLE_TYPE,
      ...props,
    };

    wrapper = shallowMount(AssigneeAvatarLink, {
      propsData,
    });
  }

  const findUserLink = () => wrapper.findComponent(GlLink);

  it('has the root url present in the assigneeUrl method', () => {
    createComponent();

    expect(wrapper.attributes().href).toEqual(userDataMock().web_url);
  });

  it('renders assignee avatar', () => {
    createComponent();

    expect(wrapper.findComponent(AssigneeAvatar).props()).toEqual(
      expect.objectContaining({
        issuableType: TEST_ISSUABLE_TYPE,
        user: userDataMock(),
      }),
    );
  });

  it('passes the correct user id for REST API', () => {
    createComponent({
      tooltipHasName: true,
      issuableType: 'issue',
      user: userDataMock(),
    });

    expect(findUserLink().attributes('data-user-id')).toBe(String(userDataMock().id));
  });

  it('passes the correct user id for GraphQL API', () => {
    const userId = userDataMock().id;

    createComponent({
      tooltipHasName: true,
      issuableType: 'issue',
      user: { ...userDataMock(), id: convertToGraphQLId(TYPENAME_USER, userId) },
    });

    expect(findUserLink().attributes('data-user-id')).toBe(String(userId));
  });

  it('passes the correct username, cannotMerge, and CSS class for popover support', () => {
    const moctUserData = userDataMock();
    const { id, username } = moctUserData;

    createComponent({
      tooltipHasName: true,
      issuableType: 'merge_request',
      user: { ...moctUserData, can_merge: false },
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
