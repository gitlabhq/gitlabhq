import { mountExtended } from 'helpers/vue_test_utils_helper';
import MemberActivity from '~/members/components/table/member_activity.vue';
import { member as memberMock, group as groupLinkMock } from '../../mock_data';

describe('MemberActivity', () => {
  let wrapper;

  const defaultPropsData = {
    member: memberMock,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(MemberActivity, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  describe('with a member that has all fields', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders `User created`, `Access granted`, and `Last activity` fields', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('with a member that does not have all of the fields', () => {
    beforeEach(() => {
      createComponent({ propsData: { member: groupLinkMock } });
    });

    it('renders `User created` field', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
