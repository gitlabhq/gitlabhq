import { GlButton, GlBadge, GlIcon, GlAvatarLabeled, GlAvatarLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TYPE_ISSUE, WORKSPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';
import { mockIssuableShowProps, mockIssuable } from '../mock_data';

describe('IssuableHeader component', () => {
  let wrapper;

  beforeEach(() => {
    window.gon.gitlab_url = 'http://0.0.0.0';
  });

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findBlockedIcon = () => wrapper.findByTestId('blocked').findComponent(GlIcon);
  const findButton = () => wrapper.findComponent(GlButton);
  const findGlAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findHeaderActions = () => wrapper.findByTestId('header-actions');
  const findTaskStatus = () => wrapper.findByTestId('task-status');

  const createComponent = (props = {}, { stubs } = {}) => {
    wrapper = shallowMountExtended(IssuableHeader, {
      propsData: {
        ...mockIssuable,
        ...mockIssuableShowProps,
        issuableType: TYPE_ISSUE,
        workspaceType: WORKSPACE_PROJECT,
        ...props,
      },
      slots: {
        'status-badge': 'Open',
        'header-actions': `
        <button class="js-close">Close issuable</button>
        <a class="js-new" href="/gitlab-org/gitlab-shell/-/issues/new">New issuable</a>
      `,
      },
      stubs: {
        GlSprintf,
        ...stubs,
      },
    });
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  it('renders issuable status icon and text', () => {
    createComponent();
    const status = findBadge();
    const statusIcon = status.findComponent(GlIcon);

    expect(status.text()).toBe('Open');
    expect(statusIcon.props('name')).toBe(mockIssuableShowProps.statusIcon);
    expect(statusIcon.attributes('class')).toBe(mockIssuableShowProps.statusIconClass);
  });

  it('renders blocked icon when issuable is blocked', () => {
    createComponent({ blocked: true });

    expect(findBlockedIcon().props('name')).toBe('lock');
  });

  it('renders confidential icon when issuable is confidential', () => {
    createComponent({ confidential: true });

    expect(wrapper.findComponent(ConfidentialityBadge).props()).toEqual({
      issuableType: 'issue',
      workspaceType: 'project',
    });
  });

  describe('author', () => {
    it('renders avatar', () => {
      createComponent();
      const { username, name, webUrl, avatarUrl } = mockIssuable.author;
      const avatar = findGlAvatarLink();

      expect(avatar.attributes()).toMatchObject({
        'data-user-id': '1',
        'data-username': username,
        'data-name': name,
        href: webUrl,
      });
      expect(avatar.findComponent(GlAvatarLabeled).attributes()).toMatchObject({
        size: '24',
        src: avatarUrl,
        label: name,
      });
      expect(avatar.findComponent(GlAvatarLabeled).findComponent(GlIcon).exists()).toBe(false);
    });

    describe('when author exists outside of GitLab', () => {
      it("renders 'external-link' icon in avatar label", () => {
        createComponent(
          {
            author: {
              ...mockIssuable.author,
              webUrl: 'https://jira.com/test-user/author.jpg',
            },
          },
          {
            stubs: { GlAvatarLabeled },
          },
        );
        const icon = wrapper.findComponent(GlAvatarLabeled).findComponent(GlIcon);

        expect(icon.props('name')).toBe('external-link');
      });
    });
  });

  describe('task status', () => {
    it('renders task status text when `taskCompletionStatus` prop is defined', () => {
      createComponent();

      expect(findTaskStatus().text()).toContain('0 of 5 checklist items completed');
    });

    it('does not render task status text when tasks count is 0', () => {
      createComponent({ taskCompletionStatus: { count: 0, completedCount: 0 } });

      expect(findTaskStatus().exists()).toBe(false);
    });
  });

  it('renders header actions', () => {
    createComponent();
    const headerActions = findHeaderActions();

    expect(headerActions.find('button.js-close').exists()).toBe(true);
    expect(headerActions.find('a.js-new').exists()).toBe(true);
  });

  describe('sidebar toggle button', () => {
    beforeEach(() => {
      setHTMLFixture('<button class="js-toggle-right-sidebar-button">Collapse sidebar</button>');
      createComponent();
    });

    it('renders', () => {
      expect(findButton().props('icon')).toBe('chevron-double-lg-left');
    });

    describe('when clicked', () => {
      it('emits a "toggle" event', () => {
        findButton().vm.$emit('click');

        expect(wrapper.emitted('toggle')).toEqual([[]]);
      });

      it('dispatches `click` event on sidebar toggle button', () => {
        const toggleSidebarButton = document.querySelector('.js-toggle-right-sidebar-button');
        const dispatchEvent = jest
          .spyOn(toggleSidebarButton, 'dispatchEvent')
          .mockImplementation(jest.fn);

        findButton().vm.$emit('click');

        expect(dispatchEvent).toHaveBeenCalledWith(expect.objectContaining({ type: 'click' }));
      });
    });
  });
});
