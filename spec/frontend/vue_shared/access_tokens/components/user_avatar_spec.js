import { GlAvatarLabeled, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { getUser } from '~/api/user_api';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import UserAvatar from '~/vue_shared/access_tokens/components/user_avatar.vue';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/api/user_api');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('UserAvatar', () => {
  let wrapper;

  const user = {
    name: 'Test User',
    username: 'testuser',
    avatar_url: 'http://gitlab.example.com/avatar.png',
  };

  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = () => {
    wrapper = shallowMount(UserAvatar, {
      propsData: { id: 1 },
    });
  };

  beforeEach(() => {
    getUser.mockResolvedValue({ data: user });
  });

  it('renders an icon when loading', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findAvatar().exists()).toBe(false);
  });

  it('renders avatar when not loading', async () => {
    createComponent();
    await waitForPromises();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findAvatar().attributes()).toMatchObject({
      label: user.name,
      sublabel: `@${user.username}`,
      src: user.avatar_url,
      size: '32',
    });
  });

  it('renders nothing if the fetch fails', async () => {
    const error = new Error('Fetch failed');
    getUser.mockRejectedValue(error);
    createComponent();
    await waitForPromises();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findAvatar().exists()).toBe(false);
    expect(Sentry.captureException).toHaveBeenCalledWith(error);
  });
});
