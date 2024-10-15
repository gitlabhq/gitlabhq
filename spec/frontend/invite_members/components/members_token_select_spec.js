import { GlTokenSelector } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as UserApi from '~/api/user_api';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';
import { VALID_TOKEN_BACKGROUND, INVALID_TOKEN_BACKGROUND } from '~/invite_members/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const label = 'testgroup';
const placeholder = 'Search for a member';
const user1 = { id: 1, name: 'John Smith', username: 'one_1', avatar_url: '' };
const user2 = { id: 2, name: 'Jane Doe', username: 'two_2', avatar_url: '' };
const allUsers = [user1, user2];
const handleEnterSpy = jest.fn();

/** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
let wrapper;

const createComponent = ({ props = {}, glFeatures = {} } = {}) => {
  wrapper = mountExtended(MembersTokenSelect, {
    propsData: {
      ariaLabelledby: label,
      invalidMembers: {},
      placeholder,
      ...props,
    },
    provide: { glFeatures },
  });
};

beforeEach(() => {
  createComponent();
});

describe('MembersTokenSelect', () => {
  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);

  describe('rendering the token-selector component', () => {
    it('renders with the correct props', () => {
      const expectedProps = {
        ariaLabelledby: label,
        placeholder,
      };

      expect(findTokenSelector().props()).toEqual(expect.objectContaining(expectedProps));
    });
  });

  describe('when there are invalidMembers', () => {
    it('adds in the correct class values for the tokens', async () => {
      const badToken = { ...user1, class: INVALID_TOKEN_BACKGROUND };
      const goodToken = { ...user2, class: VALID_TOKEN_BACKGROUND };

      findTokenSelector().vm.$emit('input', [user1, user2]);

      await waitForPromises();

      expect(findTokenSelector().props('selectedTokens')).toEqual([user1, user2]);

      await wrapper.setProps({ invalidMembers: { one_1: 'bad stuff' } });

      expect(findTokenSelector().props('selectedTokens')).toEqual([badToken, goodToken]);
    });

    it('does not change class when invalid members are cleared', async () => {
      // arrange - invalidMembers is non-empty and then tokens are added
      await wrapper.setProps({ invalidMembers: { one_1: 'bad stuff' } });
      findTokenSelector().vm.$emit('input', [user1, user2]);
      await waitForPromises();

      // act - invalidMembers clears out
      await wrapper.setProps({ invalidMembers: {} });

      // assert - we didn't try to update the tokens
      expect(findTokenSelector().props('selectedTokens')).toEqual([user1, user2]);
    });
  });

  describe('when there are users with warning', () => {
    it('shows warning token selector', async () => {
      createComponent({ props: { usersWithWarning: { [user1.username]: 'warning message' } } });
      findTokenSelector().vm.$emit('input', [user1]);
      await waitForPromises();

      const warningMemberIcon = wrapper.findByTestId(`warning-icon-${user1.id}`);

      expect(warningMemberIcon.props('name')).toBe('warning');
    });
  });

  describe('users', () => {
    beforeEach(() => {
      jest.spyOn(UserApi, 'getUsers').mockResolvedValue({ data: allUsers });
      createComponent();
    });

    describe('when input is manually focused', () => {
      it('calls the API and sets dropdown items as request result', async () => {
        const tokenSelector = findTokenSelector();

        tokenSelector.vm.$emit('focus');

        await waitForPromises();

        expect(tokenSelector.props('dropdownItems')).toMatchObject(allUsers);
        expect(tokenSelector.props('hideDropdownWithNoItems')).toBe(false);
      });
    });

    describe('when text input is typed in', () => {
      let tokenSelector;

      beforeEach(() => {
        tokenSelector = findTokenSelector();
      });

      it('calls the API with search parameter', async () => {
        const searchParam = 'One';

        tokenSelector.vm.$emit('text-input', searchParam);

        await waitForPromises();

        expect(UserApi.getUsers).toHaveBeenCalledWith(searchParam, {
          active: true,
          without_project_bots: true,
        });
        expect(tokenSelector.props('hideDropdownWithNoItems')).toBe(false);
      });

      it('calls the API with search parameter with whitespaces and is trimmed', async () => {
        tokenSelector.vm.$emit('text-input', ' foo@bar.com ');

        await waitForPromises();

        expect(UserApi.getUsers).toHaveBeenCalledWith('foo@bar.com', {
          active: true,
          without_project_bots: true,
        });
        expect(tokenSelector.props('hideDropdownWithNoItems')).toBe(false);
      });

      describe('when input text is an email', () => {
        it.each`
          email             | result
          ${'foo@bar.com'}  | ${true}
          ${'foo@bar.com '} | ${false}
          ${' foo@bar.com'} | ${false}
          ${'foo@ba r.com'} | ${false}
          ${'fo o@bar.com'} | ${false}
        `(`with token creation validation on $email`, async ({ email, result }) => {
          tokenSelector.vm.$emit('text-input', email);

          await nextTick();

          expect(tokenSelector.props('allowUserDefinedTokens')).toBe(result);
        });
      });

      describe('when API search fails', () => {
        beforeEach(() => {
          jest.spyOn(Sentry, 'captureException');
          jest.spyOn(UserApi, 'getUsers').mockRejectedValue('error');
        });

        it('reports to sentry', async () => {
          tokenSelector.vm.$emit('text-input', 'Den');

          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith('error');
        });
      });

      it('allows tab to function as enter', () => {
        tokenSelector.vm.handleEnter = handleEnterSpy;

        tokenSelector.vm.$emit('text-input', 'username');

        tokenSelector.vm.$emit('keydown', new KeyboardEvent('keydown', { key: 'Tab' }));

        expect(handleEnterSpy).toHaveBeenCalled();
      });
    });

    describe('when user is selected', () => {
      it('emits `input` event with selected users', () => {
        findTokenSelector().vm.$emit('input', [user1, user2]);

        expect(wrapper.emitted().input[0][0]).toEqual([user1, user2]);
      });
    });

    describe('when user is removed', () => {
      it('emits `clear` event', () => {
        findTokenSelector().vm.$emit('token-remove', [user1]);

        expect(wrapper.emitted('clear')).toEqual([[]]);
        expect(wrapper.emitted('token-remove')).toBeUndefined();
      });

      it('emits `token-remove` event with the token when there are still tokens selected', () => {
        findTokenSelector().vm.$emit('input', [user1, user2]);
        findTokenSelector().vm.$emit('token-remove', [user1]);

        expect(wrapper.emitted('token-remove')).toEqual([[[user1]]]);
        expect(wrapper.emitted('clear')).toBeUndefined();
      });
    });
  });

  describe('when text input is blurred', () => {
    it('clears text input', async () => {
      const tokenSelector = findTokenSelector();

      tokenSelector.vm.$emit('blur');

      await nextTick();

      expect(tokenSelector.props('hideDropdownWithNoItems')).toBe(false);
    });
  });

  describe('when component is mounted for a group using a SAML provider', () => {
    const searchParam = 'name';
    const samlProviderId = 123;

    beforeEach(() => {
      jest.spyOn(UserApi, 'getUsers').mockResolvedValue({ data: allUsers });

      createComponent({
        props: { filterId: samlProviderId, usersFilter: 'saml_provider_id' },
      });

      findTokenSelector().vm.$emit('text-input', searchParam);
    });

    it('calls the API with the saml provider ID param', () => {
      expect(UserApi.getUsers).toHaveBeenCalledWith(searchParam, {
        active: true,
        without_project_bots: true,
        saml_provider_id: samlProviderId,
      });
    });
  });
});
