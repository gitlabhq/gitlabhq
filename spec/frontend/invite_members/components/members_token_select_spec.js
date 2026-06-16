import { GlTokenSelector } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';
import {
  VALID_TOKEN_BACKGROUND,
  INVALID_TOKEN_BACKGROUND,
  MAX_INVITES,
} from '~/invite_members/constants';
import * as MembersUtils from '~/invite_members/utils/member_utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const label = 'testgroup';
const placeholder = 'Search for a member';
const user1 = { id: 1, name: 'John Smith', username: 'one_1', avatar_url: '' };
const user2 = { id: 2, name: 'Jane Doe', username: 'two_2', avatar_url: '' };
const allUsers = [user1, user2];
const handleEnterSpy = jest.fn();

/** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
let wrapper;
const searchUrl = 'https://example.com/gitlab/groups/mygroup/-/group_members/invite_search.json';

const createComponent = ({ props = {} } = {}) => {
  wrapper = mountExtended(MembersTokenSelect, {
    propsData: {
      ariaLabelledby: label,
      invalidMembers: {},
      placeholder,
      ...props,
    },
    provide: { searchUrl },
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

    it('renders with a taller minimum height', () => {
      expect(findTokenSelector().props('containerClass')).toContain('gl-min-h-13');
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
      await wrapper.setProps({ invalidMembers: { one_1: 'bad stuff' } });
      findTokenSelector().vm.$emit('input', [user1, user2]);
      await waitForPromises();

      await wrapper.setProps({ invalidMembers: {} });

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
    let tokenSelector;

    beforeEach(() => {
      jest.spyOn(MembersUtils, 'searchUsers').mockResolvedValue({ data: allUsers });
      createComponent();
      tokenSelector = findTokenSelector();
    });

    describe('minimum character search threshold', () => {
      it('does NOT trigger a search when typing 1 character', async () => {
        tokenSelector.vm.$emit('text-input', 'a');

        await waitForPromises();

        expect(MembersUtils.searchUsers).not.toHaveBeenCalled();
      });

      it('does NOT trigger a search when typing 2 characters', async () => {
        tokenSelector.vm.$emit('text-input', 'ab');

        await waitForPromises();

        expect(MembersUtils.searchUsers).not.toHaveBeenCalled();
      });

      it('triggers a search when typing 3+ characters', async () => {
        tokenSelector.vm.$emit('text-input', 'abc');

        await waitForPromises();

        expect(MembersUtils.searchUsers).toHaveBeenCalledWith(searchUrl, 'abc');
      });
    });

    describe('when text input is typed in', () => {
      it('calls the API with search parameter when 3+ characters', async () => {
        const searchParam = 'One';

        tokenSelector.vm.$emit('text-input', searchParam);

        await waitForPromises();

        expect(MembersUtils.searchUsers).toHaveBeenCalledWith(searchUrl, searchParam);
      });

      describe('when input text is an email', () => {
        it.each`
          email              | result
          ${'foo@bar.com'}   | ${true}
          ${' foo@bar.com'}  | ${false}
          ${'foo@ba r.com'}  | ${false}
          ${'fo o@bar.com'}  | ${false}
          ${'foo@bar'}       | ${true}
          ${'a@b.c'}         | ${true}
          ${'a@@b.c'}        | ${false}
          ${'user@host@.co'} | ${false}
        `(`with token creation validation on $email`, async ({ email, result }) => {
          tokenSelector.vm.$emit('text-input', email);

          await nextTick();

          expect(tokenSelector.props('allowUserDefinedTokens')).toBe(result);
        });
      });

      describe('when API search fails', () => {
        beforeEach(() => {
          jest.spyOn(Sentry, 'captureException');
          jest.spyOn(MembersUtils, 'searchUsers').mockRejectedValue('error');
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

      it('emits tokenization-state-change with true when text is typed', async () => {
        tokenSelector.vm.$emit('text-input', 'test');
        await nextTick();

        expect(wrapper.emitted('tokenization-state-change')).toEqual([[true]]);
      });

      it('emits tokenization-state-change with false when typed text is cleared', async () => {
        tokenSelector.vm.$emit('text-input', 'test');
        await nextTick();

        tokenSelector.vm.$emit('text-input', '');
        await nextTick();

        expect(wrapper.emitted('tokenization-state-change')).toEqual([[true], [false]]);
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
    it('hides dropdown when no valid email or users', async () => {
      const tokenSelector = findTokenSelector();

      tokenSelector.vm.$emit('blur');

      await nextTick();

      expect(tokenSelector.props('hideDropdownWithNoItems')).toBe(true);
    });
  });

  describe('invite cap', () => {
    const generateTokens = (count) =>
      Array.from({ length: count }, (_, i) => ({
        id: i + 1,
        name: `User ${i + 1}`,
        username: `user_${i + 1}`,
        avatar_url: '',
      }));

    it(`disables input after adding ${MAX_INVITES} tokens`, async () => {
      createComponent();
      const tokens = generateTokens(MAX_INVITES);

      findTokenSelector().vm.$emit('input', tokens);

      await nextTick();

      expect(findTokenSelector().props('textInputAttrs')).toMatchObject({ readonly: true });
    });

    it('emits invite-cap-reached when limit is reached', async () => {
      createComponent();
      const tokens = generateTokens(MAX_INVITES);

      findTokenSelector().vm.$emit('input', tokens);

      await nextTick();

      expect(wrapper.emitted('invite-cap-reached').at(-1)[0]).toBe(true);
    });

    it('re-enables input after removing a token below the cap', async () => {
      createComponent();
      const tokens = generateTokens(MAX_INVITES);

      findTokenSelector().vm.$emit('input', tokens);
      await nextTick();

      expect(findTokenSelector().props('textInputAttrs')).toMatchObject({ readonly: true });

      findTokenSelector().vm.$emit('input', tokens.slice(0, MAX_INVITES - 1));
      await nextTick();

      expect(findTokenSelector().props('textInputAttrs')).not.toHaveProperty('readonly');
      expect(wrapper.emitted('invite-cap-reached').at(-1)[0]).toBe(false);
    });

    it('short-circuits handleTextInput when cap is reached', async () => {
      jest.spyOn(MembersUtils, 'searchUsers').mockResolvedValue({ data: allUsers });
      createComponent();
      const tokens = generateTokens(MAX_INVITES);

      findTokenSelector().vm.$emit('input', tokens);
      await nextTick();

      findTokenSelector().vm.$emit('text-input', 'newuser@example.com');
      await waitForPromises();

      expect(MembersUtils.searchUsers).not.toHaveBeenCalled();
    });
  });
});
