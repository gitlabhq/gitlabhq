import { GlTokenSelector } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import * as UserApi from '~/api/user_api';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';

const label = 'testgroup';
const placeholder = 'Search for a member';
const user1 = { id: 1, name: 'John Smith', username: 'one_1', avatar_url: '' };
const user2 = { id: 2, name: 'Jane Doe', username: 'two_2', avatar_url: '' };
const allUsers = [user1, user2];

const createComponent = () => {
  return shallowMount(MembersTokenSelect, {
    propsData: {
      ariaLabelledby: label,
      placeholder,
    },
    stubs: {
      GlTokenSelector: stubComponent(GlTokenSelector),
    },
  });
};

describe('MembersTokenSelect', () => {
  let wrapper;

  beforeEach(() => {
    jest.spyOn(UserApi, 'getUsers').mockResolvedValue({ data: allUsers });
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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

  describe('users', () => {
    describe('when input is focused for the first time (modal auto-focus)', () => {
      it('does not call the API', async () => {
        findTokenSelector().vm.$emit('focus');

        await waitForPromises();

        expect(UserApi.getUsers).not.toHaveBeenCalled();
      });
    });

    describe('when input is manually focused', () => {
      it('calls the API and sets dropdown items as request result', async () => {
        const tokenSelector = findTokenSelector();

        tokenSelector.vm.$emit('focus');
        tokenSelector.vm.$emit('blur');
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

        expect(UserApi.getUsers).toHaveBeenCalledWith(
          searchParam,
          wrapper.vm.$options.queryOptions,
        );
        expect(tokenSelector.props('hideDropdownWithNoItems')).toBe(false);
      });

      describe('when input text is an email', () => {
        it('allows user defined tokens', async () => {
          tokenSelector.vm.$emit('text-input', 'foo@bar.com');

          await nextTick();

          expect(tokenSelector.props('allowUserDefinedTokens')).toBe(true);
        });
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
      });

      it('does not emit `clear` event when there are still tokens selected', () => {
        findTokenSelector().vm.$emit('input', [user1, user2]);
        findTokenSelector().vm.$emit('token-remove', [user1]);

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
});
