import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import GreetingHeader from '~/homepage/components/greeting_header.vue';
import SetStatusModal from '~/set_status_modal/set_status_modal_wrapper.vue';
import getUserStatusQuery from '~/homepage/graphql/queries/user_status.query.graphql';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { GREETING_MESSAGES } from '~/homepage/constants';
import { buildTimeAwareGreetings } from '~/homepage/utils/build_time_aware_greetings';
import { useFakeDate } from 'helpers/fake_date';

const FIXED_DATE = new Date(2025, 2, 19, 10, 0); // Wednesday 10am

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

  const emptyMessageResponse = {
    data: {
      currentUser: {
        id: 'gid://gitlab/User/1',
        status: {
          emoji: 'rocket',
          message: '',
          availability: 'BUSY',
          clearStatusAt: '',
        },
      },
    },
  };

  const nullMessageResponse = {
    data: {
      currentUser: {
        id: 'gid://gitlab/User/1',
        status: {
          emoji: 'rocket',
          message: null,
          availability: 'BUSY',
          clearStatusAt: '',
        },
      },
    },
  };

  const statusQuerySuccessHandler = jest.fn().mockResolvedValue(statusResponse);
  const statusQueryNoStatusHandler = jest.fn().mockResolvedValue(noStatusResponse);
  const statusQueryEmptyMessageHandler = jest.fn().mockResolvedValue(emptyMessageResponse);
  const statusQueryNullMessageHandler = jest.fn().mockResolvedValue(nullMessageResponse);
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
        'gl-emoji': true,
      },
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findName = () => wrapper.find('[data-testid="greeting-name"]');
  const findGreeting = () => wrapper.find('[data-testid="greeting-message"]');
  const findStatusBadge = () => wrapper.find('[data-testid="status-emoji-badge"]');
  const findStatusEmoji = () => {
    const stub = wrapper.find('gl-emoji-stub');
    return stub.exists() ? stub : wrapper.find('gl-emoji');
  };
  const findAvatarButton = () => wrapper.find('[data-testid="status-modal-trigger"]');
  const findStatusModal = () => wrapper.findComponent(SetStatusModal);

  describe('Name display', () => {
    it('renders full name above the greeting', () => {
      createComponent();
      expect(findName().text()).toBe('John Doe');
    });

    it('falls back to username when full name is not available', () => {
      createComponent({ gonData: { current_user_fullname: null } });
      expect(findName().text()).toBe('johndoe');
    });

    it('falls back to username when full name is empty', () => {
      createComponent({ gonData: { current_user_fullname: '' } });
      expect(findName().text()).toBe('johndoe');
    });

    it('does not render name line when no name or username is available', () => {
      createComponent({ gonData: { current_user_fullname: null, current_username: null } });
      expect(findName().exists()).toBe(false);
    });

    it('handles single name correctly', () => {
      createComponent({ gonData: { current_user_fullname: 'Madonna' } });
      expect(findName().text()).toBe('Madonna');
    });

    it('uses full name for multi-word names', () => {
      createComponent({ gonData: { current_user_fullname: 'John Doe Smith Jr' } });
      expect(findName().text()).toBe('John Doe Smith Jr');
    });

    it('handles name with special characters', () => {
      createComponent({ gonData: { current_user_fullname: "O'Brien" } });
      expect(findName().text()).toBe("O'Brien");
    });

    it('trims whitespace from full name', () => {
      createComponent({ gonData: { current_user_fullname: '  John  Doe  ' } });
      expect(findName().text()).toBe('John  Doe');
    });

    it('truncates very long names gracefully', () => {
      const longName = 'A'.repeat(100);
      createComponent({ gonData: { current_user_fullname: longName } });
      expect(findName().classes()).toContain('gl-truncate');
    });
  });

  describe('Greeting', () => {
    useFakeDate(FIXED_DATE);

    it('renders a greeting in the h1 element', () => {
      createComponent();
      const greeting = findGreeting();
      expect(greeting.exists()).toBe(true);
      expect(greeting.element.tagName).toBe('H1');
      expect(greeting.text().length).toBeGreaterThan(0);
    });

    it('renders a greeting from the combined greeting pool', () => {
      createComponent();
      const allGreetings = [...GREETING_MESSAGES, ...buildTimeAwareGreetings(FIXED_DATE)];
      expect(allGreetings).toContain(findGreeting().text());
    });
  });

  describe('Avatar', () => {
    it('renders avatar with correct props', () => {
      createComponent({
        gonData: { current_user_avatar_url: 'https://gitlab.com/user-avatar.png' },
      });

      expect(findAvatar().props()).toMatchObject({
        src: 'https://gitlab.com/user-avatar.png',
        alt: 'avatar for John Doe',
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

  describe('Tooltips', () => {
    describe('when no status is set', () => {
      beforeEach(() => {
        createComponent({ statusQueryHandler: statusQueryNoStatusHandler });
        return waitForPromises();
      });

      it('shows "Set status" tooltip on avatar button', () => {
        const tooltip = getBinding(findAvatarButton().element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('Set status');
      });
    });

    describe('when status is set with message', () => {
      beforeEach(() => {
        createComponent({ statusQueryHandler: statusQuerySuccessHandler });
        return waitForPromises();
      });

      it('shows status message as tooltip on status badge', () => {
        const tooltip = getBinding(findStatusBadge().element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('Working on something');
      });
    });

    describe('when status is set but message is empty', () => {
      beforeEach(() => {
        createComponent({ statusQueryHandler: statusQueryEmptyMessageHandler });
        return waitForPromises();
      });

      it('shows "Set status" tooltip when status message is empty', () => {
        const tooltip = getBinding(findStatusBadge().element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('Set status');
      });
    });

    describe('when status is set but message is null', () => {
      beforeEach(() => {
        createComponent({ statusQueryHandler: statusQueryNullMessageHandler });
        return waitForPromises();
      });

      it('shows "Set status" tooltip when status message is null', () => {
        expect(findStatusBadge().exists()).toBe(true);
        const tooltip = getBinding(findStatusBadge().element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('Set status');
      });
    });
  });

  describe('Status Modal', () => {
    describe('when no status is set', () => {
      beforeEach(() => {
        createComponent({ statusQueryHandler: statusQueryNoStatusHandler });
        return waitForPromises();
      });

      it('mounts status modal only after clicking avatar', async () => {
        expect(findStatusModal().exists()).toBe(false);
        expect(findAvatarButton().exists()).toBe(true);

        await findAvatarButton().trigger('click');
        await nextTick();

        expect(findStatusModal().exists()).toBe(true);
      });

      it('passes empty props when no status exists', async () => {
        await findAvatarButton().trigger('click');
        await nextTick();

        expect(findStatusModal().props()).toMatchObject({
          currentEmoji: '',
          currentMessage: '',
          currentAvailability: '',
          currentClearStatusAfter: '',
        });
      });
    });

    describe('when status is set', () => {
      beforeEach(() => {
        createComponent();
        return waitForPromises();
      });

      it('mounts status modal only after clicking status badge', async () => {
        expect(findStatusModal().exists()).toBe(false);
        expect(findStatusBadge().exists()).toBe(true);

        await findStatusBadge().trigger('click');
        await nextTick();

        expect(findStatusModal().exists()).toBe(true);
      });

      it('passes correct props to status modal', async () => {
        await findStatusBadge().trigger('click');
        await nextTick();

        expect(findStatusModal().props()).toMatchObject({
          currentEmoji: 'rocket',
          currentMessage: 'Working on something',
          currentAvailability: 'BUSY',
          currentClearStatusAfter: '2025-09-04T14:44:43Z',
        });
      });
    });
  });
});
