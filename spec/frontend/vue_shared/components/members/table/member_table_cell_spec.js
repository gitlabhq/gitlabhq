import { mount, createLocalVue } from '@vue/test-utils';
import { MEMBER_TYPES } from '~/vue_shared/components/members/constants';
import { member as memberMock, group, invite, accessRequest } from '../mock_data';
import MembersTableCell from '~/vue_shared/components/members/table/members_table_cell.vue';

describe('MemberList', () => {
  const WrappedComponent = {
    props: {
      memberType: {
        type: String,
        required: true,
      },
    },
    render(createElement) {
      return createElement('div', this.memberType);
    },
  };

  const localVue = createLocalVue();
  localVue.component('wrapped-component', WrappedComponent);

  let wrapper;

  const createComponent = propsData => {
    wrapper = mount(MembersTableCell, {
      localVue,
      propsData,
      scopedSlots: {
        default: '<wrapped-component :member-type="props.memberType" />',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  test.each`
    member           | expectedMemberType
    ${memberMock}    | ${MEMBER_TYPES.user}
    ${group}         | ${MEMBER_TYPES.group}
    ${invite}        | ${MEMBER_TYPES.invite}
    ${accessRequest} | ${MEMBER_TYPES.accessRequest}
  `(
    'sets scoped slot prop `memberType` to $expectedMemberType',
    ({ member, expectedMemberType }) => {
      createComponent({ member });

      expect(wrapper.find(WrappedComponent).props('memberType')).toBe(expectedMemberType);
    },
  );
});
