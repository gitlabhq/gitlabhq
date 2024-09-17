import { mountExtended } from 'helpers/vue_test_utils_helper';
import MemberSource from '~/members/components/table/member_source.vue';
import PrivateIcon from '~/members/components/icons/private_icon.vue';
import { directMember, inheritedMember, sharedMember, privateGroup } from '../../mock_data';

describe('MemberSource', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = mountExtended(MemberSource, {
      propsData: {
        member: directMember,
        ...propsData,
      },
    });
  };

  describe('when source is private', () => {
    beforeEach(() => {
      createComponent({
        member: privateGroup,
      });
    });

    it('displays private with icon', () => {
      expect(wrapper.findByText('Private').exists()).toBe(true);
      expect(wrapper.findComponent(PrivateIcon).exists()).toBe(true);
    });
  });

  describe('direct member', () => {
    describe('when created by is available', () => {
      it('displays "Direct member by <user name>"', () => {
        createComponent();

        expect(wrapper.text()).toBe(`Direct member by ${directMember.createdBy.name}`);
        expect(
          wrapper.findByRole('link', { name: directMember.createdBy.name }).attributes('href'),
        ).toBe(directMember.createdBy.webUrl);
      });
    });

    describe('when created by is not available', () => {
      it('displays "Direct member"', () => {
        createComponent({
          member: {
            ...directMember,
            createdBy: undefined,
          },
        });

        expect(wrapper.text()).toBe('Direct member');
      });
    });
  });

  describe('inherited member', () => {
    beforeEach(() => {
      createComponent({
        member: inheritedMember,
      });
    });

    it('displays "Inherited from <group name>"', () => {
      expect(wrapper.text()).toBe(`Inherited from ${inheritedMember.source.fullName}`);
      expect(
        wrapper.findByRole('link', { name: inheritedMember.source.fullName }).attributes('href'),
      ).toBe(inheritedMember.source.webUrl);
    });
  });

  describe('shared member', () => {
    beforeEach(() => {
      createComponent({
        member: sharedMember,
      });
    });

    it('displays "Invited group <group name>"', () => {
      expect(wrapper.text()).toBe(`Invited group ${sharedMember.source.fullName}`);
      expect(
        wrapper.findByRole('link', { name: sharedMember.source.fullName }).attributes('href'),
      ).toBe(sharedMember.source.webUrl);
    });
  });
});
