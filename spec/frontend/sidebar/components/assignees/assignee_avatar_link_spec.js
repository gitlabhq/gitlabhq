import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import AssigneeAvatar from '~/sidebar/components/assignees/assignee_avatar.vue';
import AssigneeAvatarLink from '~/sidebar/components/assignees/assignee_avatar_link.vue';
import userDataMock from '../../user_data_mock';

const TOOLTIP_PLACEMENT = 'bottom';
const { name: USER_NAME } = userDataMock();
const TEST_ISSUABLE_TYPE = 'merge_request';

describe('AssigneeAvatarLink component', () => {
  let wrapper;

  function createComponent(props = {}) {
    const propsData = {
      user: userDataMock(),
      showLess: true,
      rootPath: TEST_HOST,
      tooltipPlacement: TOOLTIP_PLACEMENT,
      singleUser: false,
      issuableType: TEST_ISSUABLE_TYPE,
      ...props,
    };

    wrapper = shallowMount(AssigneeAvatarLink, {
      propsData,
    });
  }

  const findTooltipText = () => wrapper.attributes('title');
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

  describe.each`
    issuableType       | tooltipHasName | canMerge | expected
    ${'merge_request'} | ${true}        | ${true}  | ${USER_NAME}
    ${'merge_request'} | ${true}        | ${false} | ${`${USER_NAME} (cannot merge)`}
    ${'merge_request'} | ${false}       | ${true}  | ${''}
    ${'merge_request'} | ${false}       | ${false} | ${'Cannot merge'}
    ${'issue'}         | ${true}        | ${true}  | ${USER_NAME}
    ${'issue'}         | ${true}        | ${false} | ${USER_NAME}
    ${'issue'}         | ${false}       | ${true}  | ${''}
    ${'issue'}         | ${false}       | ${false} | ${''}
  `(
    'with $issuableType and tooltipHasName=$tooltipHasName and canMerge=$canMerge',
    ({ issuableType, tooltipHasName, canMerge, expected }) => {
      beforeEach(() => {
        createComponent({
          issuableType,
          tooltipHasName,
          user: {
            ...userDataMock(),
            can_merge: canMerge,
          },
        });
      });

      it('sets tooltip', () => {
        expect(findTooltipText()).toBe(expected);
      });
    },
  );

  describe.each`
    tooltipHasName | name               | availability | canMerge | expected
    ${true}        | ${"Rabbit O'Hare"} | ${''}        | ${true}  | ${"Rabbit O'Hare"}
    ${true}        | ${"Rabbit O'Hare"} | ${'Busy'}    | ${false} | ${"Rabbit O'Hare (Busy) (cannot merge)"}
    ${true}        | ${'Root'}          | ${'Busy'}    | ${false} | ${'Root (Busy) (cannot merge)'}
    ${true}        | ${'Root'}          | ${'Busy'}    | ${true}  | ${'Root (Busy)'}
    ${true}        | ${'Root'}          | ${''}        | ${false} | ${'Root (cannot merge)'}
    ${true}        | ${'Root'}          | ${''}        | ${true}  | ${'Root'}
    ${false}       | ${'Root'}          | ${'Busy'}    | ${false} | ${'Cannot merge'}
    ${false}       | ${'Root'}          | ${'Busy'}    | ${true}  | ${''}
    ${false}       | ${'Root'}          | ${''}        | ${false} | ${'Cannot merge'}
    ${false}       | ${'Root'}          | ${''}        | ${true}  | ${''}
  `(
    "with name=$name tooltipHasName=$tooltipHasName and availability='$availability' and canMerge=$canMerge",
    ({ name, tooltipHasName, availability, canMerge, expected }) => {
      beforeEach(() => {
        createComponent({
          tooltipHasName,
          user: {
            ...userDataMock(),
            name,
            can_merge: canMerge,
            availability,
          },
        });
      });

      it(`sets tooltip to "${expected}"`, () => {
        expect(findTooltipText()).toBe(expected);
      });
    },
  );

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

  it.each`
    issuableType       | userId
    ${'merge_request'} | ${undefined}
    ${'issue'}         | ${'1'}
  `('sets data-user-id as $userId for $issuableType', ({ issuableType, userId }) => {
    createComponent({
      issuableType,
    });

    expect(findUserLink().attributes('data-user-id')).toBe(userId);
  });
});
