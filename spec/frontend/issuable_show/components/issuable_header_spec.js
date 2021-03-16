import { GlIcon, GlAvatarLabeled } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import IssuableHeader from '~/issuable_show/components/issuable_header.vue';

import { mockIssuableShowProps, mockIssuable } from '../mock_data';

const issuableHeaderProps = {
  ...mockIssuable,
  ...mockIssuableShowProps,
};

const createComponent = (propsData = issuableHeaderProps, { stubs } = {}) =>
  extendedWrapper(
    shallowMount(IssuableHeader, {
      propsData,
      slots: {
        'status-badge': 'Open',
        'header-actions': `
        <button class="js-close">Close issuable</button>
        <a class="js-new" href="/gitlab-org/gitlab-shell/-/issues/new">New issuable</a>
      `,
      },
      stubs,
    }),
  );

describe('IssuableHeader', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('authorId', () => {
      it('returns numeric ID from GraphQL ID of `author` prop', () => {
        expect(wrapper.vm.authorId).toBe(1);
      });
    });
  });

  describe('handleRightSidebarToggleClick', () => {
    beforeEach(() => {
      setFixtures('<button class="js-toggle-right-sidebar-button">Collapse sidebar</button>');
    });

    it('dispatches `click` event on sidebar toggle button', () => {
      wrapper.vm.toggleSidebarButtonEl = document.querySelector('.js-toggle-right-sidebar-button');
      jest.spyOn(wrapper.vm.toggleSidebarButtonEl, 'dispatchEvent').mockImplementation(jest.fn);

      wrapper.vm.handleRightSidebarToggleClick();

      expect(wrapper.vm.toggleSidebarButtonEl.dispatchEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'click',
        }),
      );
    });
  });

  describe('template', () => {
    it('renders issuable status icon and text', () => {
      const statusBoxEl = wrapper.findByTestId('status');

      expect(statusBoxEl.exists()).toBe(true);
      expect(statusBoxEl.find(GlIcon).props('name')).toBe(mockIssuableShowProps.statusIcon);
      expect(statusBoxEl.text()).toContain('Open');
    });

    it('renders blocked icon when issuable is blocked', async () => {
      wrapper.setProps({
        blocked: true,
      });

      await wrapper.vm.$nextTick();

      const blockedEl = wrapper.findByTestId('blocked');

      expect(blockedEl.exists()).toBe(true);
      expect(blockedEl.find(GlIcon).props('name')).toBe('lock');
    });

    it('renders confidential icon when issuable is confidential', async () => {
      wrapper.setProps({
        confidential: true,
      });

      await wrapper.vm.$nextTick();

      const confidentialEl = wrapper.findByTestId('confidential');

      expect(confidentialEl.exists()).toBe(true);
      expect(confidentialEl.find(GlIcon).props('name')).toBe('eye-slash');
    });

    it('renders issuable author avatar', () => {
      const { username, name, webUrl, avatarUrl } = mockIssuable.author;
      const avatarElAttrs = {
        'data-user-id': '1',
        'data-username': username,
        'data-name': name,
        href: webUrl,
        target: '_blank',
      };
      const avatarEl = wrapper.findByTestId('avatar');
      expect(avatarEl.exists()).toBe(true);
      expect(avatarEl.attributes()).toMatchObject(avatarElAttrs);
      expect(avatarEl.find(GlAvatarLabeled).attributes()).toMatchObject({
        size: '24',
        src: avatarUrl,
        label: name,
      });
      expect(avatarEl.find(GlAvatarLabeled).find(GlIcon).exists()).toBe(false);
    });

    it('renders tast status text when `taskCompletionStatus` prop is defined', () => {
      let taskStatusEl = wrapper.findByTestId('task-status');

      expect(taskStatusEl.exists()).toBe(true);
      expect(taskStatusEl.text()).toContain('0 of 5 tasks completed');

      const wrapperSingleTask = createComponent({
        ...issuableHeaderProps,
        taskCompletionStatus: {
          completedCount: 0,
          count: 1,
        },
      });

      taskStatusEl = wrapperSingleTask.findByTestId('task-status');

      expect(taskStatusEl.text()).toContain('0 of 1 task completed');

      wrapperSingleTask.destroy();
    });

    it('renders sidebar toggle button', () => {
      const toggleButtonEl = wrapper.findByTestId('sidebar-toggle');

      expect(toggleButtonEl.exists()).toBe(true);
      expect(toggleButtonEl.props('icon')).toBe('chevron-double-lg-left');
    });

    it('renders header actions', () => {
      const actionsEl = wrapper.findByTestId('header-actions');

      expect(actionsEl.find('button.js-close').exists()).toBe(true);
      expect(actionsEl.find('a.js-new').exists()).toBe(true);
    });

    describe('when author exists outside of GitLab', () => {
      it("renders 'external-link' icon in avatar label", () => {
        wrapper = createComponent(
          {
            ...issuableHeaderProps,
            author: {
              ...issuableHeaderProps.author,
              webUrl: 'https://jira.com/test-user/author.jpg',
            },
          },
          {
            stubs: {
              GlAvatarLabeled,
            },
          },
        );

        const avatarEl = wrapper.findComponent(GlAvatarLabeled);
        const icon = avatarEl.find(GlIcon);

        expect(icon.exists()).toBe(true);
        expect(icon.props('name')).toBe('external-link');
      });
    });
  });
});
