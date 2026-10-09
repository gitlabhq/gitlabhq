import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameCommitInfo from '~/blob/components/source_viewer/components/blame_commit_info.vue';
import CommitPopover from '~/vue_shared/components/commit_popover.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

describe('BlameCommitInfo component', () => {
  let wrapper;

  const defaultCommit = {
    title: 'Commit title',
    message: 'Commit message',
    authoredDate: '2024-01-01',
    authorGravatar: 'https://gravatar.com/avatar',
    authorName: 'Test Author',
    webPath: '/commit/abc123',
    sha: 'abc123',
  };

  const defaultAuthor = {
    id: 'gid://gitlab/User/1',
    username: 'testuser',
    webPath: '/testuser',
    avatarUrl: 'https://example.com/avatar.png',
  };

  // Stubbed by name: the real component is EE-only and resolves to an empty
  // component in FOSS.
  const AgentSessionLinkStub = {
    name: 'AgentSessionLink',
    props: ['href', 'trackingProperty'],
    template: '<a :href="href"><slot></slot></a>',
  };
  const AgentSessionPopoverStub = {
    name: 'AgentSessionPopover',
    props: ['sessionUrls'],
    template: '<div></div>',
  };

  const createComponent = (props = {}, { blameAgentSessions = true } = {}) => {
    wrapper = shallowMountExtended(BlameCommitInfo, {
      propsData: {
        commit: defaultCommit,
        ...props,
      },
      provide: { glFeatures: { blameAgentSessions } },
      stubs: {
        AgentSessionLink: AgentSessionLinkStub,
        AgentSessionPopover: AgentSessionPopoverStub,
      },
    });
  };

  const findTimeagoTooltip = () => wrapper.findComponent(TimeagoTooltip);
  const findUserAvatar = () => wrapper.findComponent(UserAvatarImage);
  const findCommitLink = () => wrapper.findByTestId('commit-message-link');
  const findPreviousBlameButton = () => wrapper.findByTestId('view-previous-blame-button');
  const findAuthorLink = () => wrapper.findByTestId('commit-author-link');
  const findCommitPopover = () => wrapper.findComponent(CommitPopover);
  const findAgentSessionLink = () => wrapper.findComponent(AgentSessionLinkStub);
  const findAgentSessionPopover = () => wrapper.findComponent(AgentSessionPopoverStub);

  describe('commit information display', () => {
    beforeEach(() => createComponent());

    it('renders commit time', () => {
      expect(findTimeagoTooltip().props('time')).toBe(defaultCommit.authoredDate);
    });

    it('renders author avatar', () => {
      expect(findUserAvatar().props('imgSrc')).toBe(defaultCommit.authorGravatar);
    });

    it('renders commit link with correct href', () => {
      expect(findCommitLink().attributes('href')).toBe(defaultCommit.webPath);
    });
  });

  describe('author avatar popover', () => {
    describe('when author data is available', () => {
      beforeEach(() => {
        createComponent({ commit: { ...defaultCommit, author: defaultAuthor } });
      });

      it('wraps avatar in a link with js-user-link class', () => {
        expect(findAuthorLink().exists()).toBe(true);
        expect(findAuthorLink().classes()).toContain('js-user-link');
        expect(findAuthorLink().attributes('href')).toBe(defaultAuthor.webPath);
      });

      it('sets data-user-id attribute from GraphQL ID', () => {
        expect(findAuthorLink().attributes('data-user-id')).toBe('1');
      });

      it('sets data-username attribute', () => {
        expect(findAuthorLink().attributes('data-username')).toBe(defaultAuthor.username);
      });
    });

    describe('when author data is not available', () => {
      beforeEach(() => createComponent());

      it('renders avatar without link wrapper', () => {
        expect(findUserAvatar().exists()).toBe(true);
        expect(findAuthorLink().exists()).toBe(false);
      });
    });
  });

  describe('commit popover', () => {
    beforeEach(() => createComponent());

    it('renders commit popover', () => {
      expect(findCommitPopover().exists()).toBe(true);
    });

    it('passes commit data to popover', () => {
      expect(findCommitPopover().props('commit')).toEqual(defaultCommit);
    });
  });

  describe('agent session link', () => {
    const sessionUrl = `${window.location.origin}/group/project/-/automate/agent-sessions/42`;

    const agentCommit = {
      ...defaultCommit,
      hasAgentSession: true,
      message: `Commit message\n\nDuo-Session: ${sessionUrl}`,
    };

    describe('when the commit was authored in an agent session', () => {
      beforeEach(() => createComponent({ commit: agentCommit }));

      it('renders the session icon with its details popover', () => {
        expect(findAgentSessionPopover().props('sessionUrls')).toEqual([sessionUrl]);
      });

      it('links to the session from the commit popover', () => {
        expect(findAgentSessionLink().props('href')).toBe(sessionUrl);
        expect(findAgentSessionLink().text()).toBe('View session');
      });

      it('tracks clicks on the commit popover link', () => {
        expect(findAgentSessionLink().props('trackingProperty')).toBe('commit_popover');
      });
    });

    describe('when the commit was not authored in an agent session', () => {
      beforeEach(() => createComponent());

      it('does not render the link or the popover', () => {
        expect(findAgentSessionLink().exists()).toBe(false);
        expect(findAgentSessionPopover().exists()).toBe(false);
      });
    });

    describe('when the blameAgentSessions feature flag is disabled', () => {
      beforeEach(() => createComponent({ commit: agentCommit }, { blameAgentSessions: false }));

      it('does not render the link or the popover', () => {
        expect(findAgentSessionLink().exists()).toBe(false);
        expect(findAgentSessionPopover().exists()).toBe(false);
      });
    });
  });

  describe('avatar fallbacks', () => {
    it.each([
      ['authorGravatar', { authorGravatar: 'gravatar-url' }, 'gravatar-url'],
      ['avatarUrl', { avatarUrl: 'avatar-url' }, 'avatar-url'],
    ])('uses %s when available', (_, commitOverrides, expectedUrl) => {
      createComponent({ commit: { ...defaultCommit, authorGravatar: null, ...commitOverrides } });

      expect(findUserAvatar().props('imgSrc')).toContain(expectedUrl);
    });
  });

  describe('commit URL fallbacks', () => {
    it.each([
      ['webPath', { webPath: '/web/path' }, '/web/path'],
      ['commitUrl', { webPath: null, commitUrl: '/commit/url' }, '/commit/url'],
    ])('uses %s when available', (_, commitOverrides, expectedUrl) => {
      createComponent({ commit: { ...defaultCommit, ...commitOverrides } });

      expect(findCommitLink().attributes('href')).toBe(expectedUrl);
    });
  });

  describe('empty commit message styling', () => {
    it('applies italic class when commit has no message or title', () => {
      createComponent({ commit: { ...defaultCommit, message: null, title: null } });

      expect(findCommitLink().classes()).toContain('gl-italic');
    });

    it('does not apply italic class when commit has message', () => {
      createComponent();

      expect(findCommitLink().classes()).not.toContain('gl-italic');
    });
  });

  describe('previous blame button', () => {
    const previousBlamePath = '/gitlab/gitlab-org/gitlab/-/blob/parent123/old/file.js?blame=1';

    it('is visible and uses the server-built path when previousBlamePath is provided', () => {
      createComponent({ previousBlamePath });

      expect(findPreviousBlameButton().classes()).not.toContain('gl-invisible');
      expect(findPreviousBlameButton().attributes('href')).toBe(previousBlamePath);
    });

    it('is hidden when previousBlamePath is missing', () => {
      createComponent();

      expect(findPreviousBlameButton().classes()).toContain('gl-invisible');
    });
  });
});
