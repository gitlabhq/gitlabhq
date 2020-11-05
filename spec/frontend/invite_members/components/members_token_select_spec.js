import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlTokenSelector } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';

const label = 'testgroup';
const placeholder = 'Search for a member';
const user1 = { id: 1, name: 'Name One', username: 'one_1', avatar_url: '' };
const user2 = { id: 2, name: 'Name Two', username: 'two_2', avatar_url: '' };
const allUsers = [user1, user2];

const createComponent = () => {
  return shallowMount(MembersTokenSelect, {
    propsData: {
      ariaLabelledby: label,
      placeholder,
    },
  });
};

describe('MembersTokenSelect', () => {
  let wrapper;

  beforeEach(() => {
    jest.spyOn(Api, 'users').mockResolvedValue({ data: allUsers });
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findTokenSelector = () => wrapper.find(GlTokenSelector);

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

        expect(Api.users).not.toHaveBeenCalled();
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
      it('calls the API with search parameter', async () => {
        const searchParam = 'One';
        const tokenSelector = findTokenSelector();

        tokenSelector.vm.$emit('text-input', searchParam);

        await waitForPromises();

        expect(Api.users).toHaveBeenCalledWith(searchParam, wrapper.vm.$options.queryOptions);
        expect(tokenSelector.props('hideDropdownWithNoItems')).toBe(false);
      });
    });

    describe('when user is selected', () => {
      it('emits `input` event with selected users', () => {
        findTokenSelector().vm.$emit('input', [
          { id: 1, name: 'John Smith' },
          { id: 2, name: 'Jane Doe' },
        ]);

        expect(wrapper.emitted().input[0][0]).toBe('1,2');
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
