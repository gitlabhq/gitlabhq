import { GlTokenSelector } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import OrganizationUsersTokenSelect from '~/organizations/admin/components/organization_users_token_select.vue';
import { MAX_ORGANIZATION_USER_INVITES } from '~/organizations/admin/constants';
import { searchUsers } from '~/invite_members/utils/member_utils';

jest.mock('~/invite_members/utils/member_utils', () => ({
  ...jest.requireActual('~/invite_members/utils/member_utils'),
  searchUsers: jest.fn(),
}));

describe('OrganizationUsersTokenSelect', () => {
  let wrapper;

  const searchUrl = '/-/autocomplete/users.json';

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(OrganizationUsersTokenSelect, {
      provide: { searchUrl },
      propsData,
    });
  };

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);
  const findInviteCapMessage = () => wrapper.findByTestId('invite-cap-message');

  const generateTokens = (length) =>
    Array.from({ length }, (_, index) => ({ id: index, username: `user${index}` }));

  beforeEach(() => {
    searchUsers.mockResolvedValue({ data: [] });
    createComponent();
  });

  it('renders a token selector', () => {
    expect(findTokenSelector().exists()).toBe(true);
  });

  it('renders the tokens passed via the selectedTokens prop', () => {
    const tokens = generateTokens(2);
    createComponent({ selectedTokens: tokens });

    expect(findTokenSelector().props('selectedTokens')).toEqual(tokens);
  });

  it('emits input with selected tokens', () => {
    const tokens = generateTokens(2);
    findTokenSelector().vm.$emit('input', tokens);

    expect(wrapper.emitted('input')[0]).toEqual([tokens]);
  });

  it('searches users after typing at least the minimum length', async () => {
    findTokenSelector().vm.$emit('text-input', 'abc');
    await waitForPromises();

    expect(searchUsers).toHaveBeenCalledWith(searchUrl, 'abc');
  });

  it('does not search users below the minimum search length', async () => {
    findTokenSelector().vm.$emit('text-input', 'ab');
    await waitForPromises();

    expect(searchUsers).not.toHaveBeenCalled();
  });

  it('passes the isValid prop to the token selector state', () => {
    createComponent({ isValid: false });

    expect(findTokenSelector().props('state')).toBe(false);
  });

  it('ignores stale responses when the query has changed', async () => {
    searchUsers.mockImplementation((_url, query) =>
      Promise.resolve({ data: [{ id: 1, name: query, username: query }] }),
    );

    findTokenSelector().vm.$emit('text-input', 'abc');
    findTokenSelector().vm.$emit('text-input', 'abcd');
    await waitForPromises();

    expect(findTokenSelector().props('dropdownItems')).toEqual([
      { id: 1, name: 'abcd', username: 'abcd', avatar_url: undefined },
    ]);
  });

  it(`marks input readonly after selecting ${MAX_ORGANIZATION_USER_INVITES} tokens`, () => {
    createComponent({ selectedTokens: generateTokens(MAX_ORGANIZATION_USER_INVITES) });

    expect(findTokenSelector().props('textInputAttrs').readonly).toBe(true);
  });

  it('does not mark input readonly below the cap', () => {
    createComponent({ selectedTokens: generateTokens(MAX_ORGANIZATION_USER_INVITES - 1) });

    expect(findTokenSelector().props('textInputAttrs').readonly).toBeUndefined();
  });

  it(`shows the invite cap message after selecting ${MAX_ORGANIZATION_USER_INVITES} tokens`, () => {
    createComponent({ selectedTokens: generateTokens(MAX_ORGANIZATION_USER_INVITES) });

    expect(findInviteCapMessage().text()).toBe(
      `You may only invite up to ${MAX_ORGANIZATION_USER_INVITES} users at a time.`,
    );
  });

  it('does not show the invite cap message below the cap', () => {
    createComponent({ selectedTokens: generateTokens(MAX_ORGANIZATION_USER_INVITES - 1) });

    expect(findInviteCapMessage().exists()).toBe(false);
  });
});
