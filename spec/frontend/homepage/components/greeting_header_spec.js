import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import GreetingHeader from '~/homepage/components/greeting_header.vue';
import SetStatusModal from '~/set_status_modal/set_status_modal_wrapper.vue';
import getUserStatusQuery from '~/homepage/graphql/queries/user_status.query.graphql';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper', () => ({
  captureException: jest.fn(),
}));

jest.mock('~/emoji', () => ({
  initEmojiMap: jest.fn().mockResolvedValue(),
  getEmojiInfo: jest.fn((name) => (name ? { e: 'rocket' } : null)),
}));

describe('GreetingHeader', () => {
  let wrapper;

  const statusResponse = {
    data: {
      currentUser: {
        id: 'gid://gitlab/User/1',
        status: {
          emoji: 'rocket',
          message: 'Working on something',
          availability: 'BUSY',
          clearStatusAt: '2025-09-04T14:44:43Z',
        },
      },
    },
  };

  const noStatusResponse = {
    data: {
      currentUser: {
        id: 'gid://gitlab/User/1',
        status: null,
      },
    },
  };

  const statusQuerySuccessHandler = jest.fn().mockResolvedValue(statusResponse);
  const statusQueryNoStatusHandler = jest.fn().mockResolvedValue(noStatusResponse);
  const statusQueryErrorHandler = jest.fn().mockRejectedValue(new Error('GraphQL Error'));

  const createComponent = ({
    gonData = {},
    statusQueryHandler = statusQuerySuccessHandler,
  } = {}) => {
    window.gon = {
      current_user_fullname: 'John Doe',
      current_username: 'johndoe',
      current_user_avatar_url: 'avatar.png',
      ...gonData,
    };

    const mockApollo = createMockApollo([[getUserStatusQuery, statusQueryHandler]]);

    wrapper = shallowMountExtended(GreetingHeader, {
      apolloProvider: mockApollo,
      stubs: {
        'gl-emoji': true, // Stub the custom element
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findGreeting = () => wrapper.find('h1');
  const findStatusBadge = () => wrapper.find('[data-testid="status-emoji-badge"]');
  const findStatusEmoji = () => wrapper.find('gl-emoji-stub');
  const findAvatarButton = () => wrapper.find('[data-testid="status-modal-trigger"]');
  const findStatusModal = () => wrapper.findComponent(SetStatusModal);

  describe('Greeting', () => {
    it('renders greeting with first name', () => {
      createComponent();
      expect(findGreeting().text()).toBe('Hi, John');
    });

    it('renders greeting with username when first name not available', () => {
      createComponent({ gonData: { current_user_fullname: null } });
      expect(findGreeting().text()).toBe('Hi, johndoe');
    });

    it('does not render greeting when user has no available name', () => {
      createComponent({ gonData: { current_user_fullname: null, current_username: null } });
      expect(findGreeting().exists()).toBe(false);
    });

    it('handles single name correctly', () => {
      createComponent({ gonData: { current_user_fullname: 'Madonna' } });
      expect(findGreeting().text()).toBe('Hi, Madonna');
    });

    it('uses only first name for multi-word names', () => {
      createComponent({ gonData: { current_user_fullname: 'John Doe Smith Jr' } });
      expect(findGreeting().text()).toBe('Hi, John');
    });

    it('handles empty string name', () => {
      createComponent({ gonData: { current_user_fullname: '' } });
      expect(findGreeting().text()).toBe('Hi, johndoe');
    });

    it('handles whitespace-only name', () => {
      createComponent({ gonData: { current_user_fullname: '   ' } });
      expect(findGreeting().text()).toBe('Hi, johndoe');
    });

    it('handles name with extra whitespace', () => {
      createComponent({ gonData: { current_user_fullname: '  John  Doe  ' } });
      expect(findGreeting().text()).toBe('Hi, John');
    });
  });

  describe('Avatar', () => {
    it('renders avatar with correct props', () => {
      createComponent({
        gonData: { current_user_avatar_url: 'https://gitlab.com/user-avatar.png' },
      });

      expect(findAvatar().props()).toMatchObject({
        src: 'https://gitlab.com/user-avatar.png',
        alt: 'avatar for John',
      });
    });
  });

  describe('User Status', () => {
    it('shows status emoji when present', async () => {
      createComponent();
      await waitForPromises();

      expect(findStatusBadge().exists()).toBe(true);
      expect(findStatusEmoji().attributes('data-name')).toBe('rocket');
    });

    it('hides status emoji when not present', async () => {
      createComponent({ statusQueryHandler: statusQueryNoStatusHandler });
      await waitForPromises();

      expect(findStatusBadge().exists()).toBe(false);
    });

    describe('when query fails', () => {
      beforeEach(() => {
        createComponent({ statusQueryHandler: statusQueryErrorHandler });
        return waitForPromises();
      });

      it('captures error with Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
      });

      it('does not show status emoji', () => {
        expect(findStatusBadge().exists()).toBe(false);
      });
    });
  });

  describe('Status Modal', () => {
    it('mounts status modal only after opening', async () => {
      createComponent();
      expect(findStatusModal().exists()).toBe(false);
      await findAvatarButton().trigger('click');
      await Vue.nextTick();
      expect(findStatusModal().exists()).toBe(true);
    });

    it('passes correct props to status modal', async () => {
      createComponent();
      await waitForPromises();
      await findAvatarButton().trigger('click');
      await Vue.nextTick();

      expect(findStatusModal().props()).toMatchObject({
        currentEmoji: 'rocket',
        currentMessage: 'Working on something',
        currentAvailability: 'BUSY',
        currentClearStatusAfter: '2025-09-04T14:44:43Z',
      });
    });

    it('passes empty props when no status exists', async () => {
      createComponent({ statusQueryHandler: statusQueryNoStatusHandler });
      await waitForPromises();
      await findAvatarButton().trigger('click');
      await Vue.nextTick();

      expect(findStatusModal().props()).toMatchObject({
        currentEmoji: '',
        currentMessage: '',
        currentAvailability: '',
        currentClearStatusAfter: '',
      });
    });
  });
});
