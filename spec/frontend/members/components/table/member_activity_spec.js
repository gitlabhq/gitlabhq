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

  const findAccessGrantedDate = () => wrapper.findByTestId('access-granted-date');

  describe('with a member that has all fields', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders `User created`, `Access granted`, and `Last activity` fields', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('when "inviteAcceptedAt" field is null and "requestAcceptedAt" field is not null', () => {
      beforeEach(() => {
        createComponent();
      });

      it('uses the "requestAcceptedAt" field to display an access granted date', () => {
        const element = findAccessGrantedDate();

        expect(element.exists()).toBe(true);
        expect(element.text()).toBe('Jul 27, 2020');
      });
    });

    describe('when "inviteAcceptedAt" field is not null', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            member: { ...memberMock, inviteAcceptedAt: '2021-08-01T16:22:46.923Z' },
          },
        });
      });

      it('uses the "inviteAcceptedAt" field to display an access granted date', () => {
        const element = findAccessGrantedDate();

        expect(element.exists()).toBe(true);
        expect(element.text()).toBe('Aug 01, 2021');
      });
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
