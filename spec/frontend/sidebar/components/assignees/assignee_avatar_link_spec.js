import { shallowMount } from '@vue/test-utils';
import { joinPaths } from '~/lib/utils/url_utility';
import userDataMock from '../../user_data_mock';
import AssigneeAvatarLink from '~/sidebar/components/assignees/assignee_avatar_link.vue';

const TOOLTIP_PLACEMENT = 'bottom';
const { name: USER_NAME } = userDataMock();

describe('AssigneeAvatarLink component', () => {
  let wrapper;

  function createComponent(props = {}) {
    const propsData = {
      user: userDataMock(),
      showLess: true,
      rootPath: 'http://localhost:3000/',
      tooltipPlacement: TOOLTIP_PLACEMENT,
      singleUser: false,
      issuableType: 'merge_request',
      ...props,
    };

    wrapper = shallowMount(AssigneeAvatarLink, {
      propsData,
      sync: false,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findTooltipText = () => wrapper.attributes('data-original-title');

  it('user who cannot merge has "cannot merge" in tooltip', () => {
    createComponent({
      user: {
        can_merge: false,
      },
    });

    expect(findTooltipText().includes('cannot merge')).toBe(true);
  });

  it('has the root url present in the assigneeUrl method', () => {
    createComponent();
    const assigneeUrl = joinPaths(
      `${wrapper.props('rootPath')}`,
      `${wrapper.props('user').username}`,
    );

    expect(wrapper.attributes().href).toEqual(assigneeUrl);
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
});
