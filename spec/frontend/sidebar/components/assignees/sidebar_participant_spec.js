import { GlAvatarLabeled, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';

const user = {
  name: 'John Doe',
  username: 'johndoe',
  webUrl: '/link',
  avatarUrl: '/avatar',
};

describe('Sidebar participant component', () => {
  let wrapper;

  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findBusyBadge = () => wrapper.find('[data-testid="busy-badge"]');
  const findAgentBadge = () => wrapper.find('[data-testid="agent-badge"]');

  const createComponent = ({
    status = null,
    issuableType = TYPE_ISSUE,
    canMerge = false,
    selected = false,
    compositeIdentityEnforced = false,
  } = {}) => {
    wrapper = shallowMount(SidebarParticipant, {
      propsData: {
        user: {
          ...user,
          canMerge,
          status,
          compositeIdentityEnforced,
        },
        issuableType,
        selected,
      },
      stubs: {
        GlAvatarLabeled,
      },
    });
  };

  describe('when is not busy and is not agent', () => {
    it('does not show `Busy` status', () => {
      createComponent();

      expect(findAvatar().props('label')).toBe(user.name);
      expect(findBusyBadge().exists()).toBe(false);
    });

    it('does not show agent badge', () => {
      createComponent();

      expect(findAgentBadge().exists()).toBe(false);
    });
  });

  describe('when is busy', () => {
    it('shows `Busy` status', () => {
      createComponent({ status: { availability: 'BUSY' } });

      expect(findBusyBadge().exists()).toBe(true);
      expect(findAgentBadge().exists()).toBe(false);
    });
  });

  describe('when is agent', () => {
    it('renders agent badge', () => {
      createComponent({ compositeIdentityEnforced: true });

      expect(findAgentBadge().exists()).toBe(true);
      expect(findBusyBadge().exists()).toBe(false);
    });
  });

  it('does not render a warning icon', () => {
    createComponent();

    expect(findIcon().exists()).toBe(false);
  });

  describe('when on merge request sidebar', () => {
    describe('when project member cannot merge', () => {
      it('renders a `cannot-merge` icon', () => {
        createComponent({ issuableType: TYPE_MERGE_REQUEST });

        expect(findIcon().exists()).toBe(true);
      });

      it('does not apply `!gl-left-6` class to an icon if participant is not selected', () => {
        createComponent({ issuableType: TYPE_MERGE_REQUEST, canMerge: false });

        expect(findIcon().classes('!gl-left-6')).toBe(false);
      });

      it('applies `!gl-left-6` class to an icon if participant is selected', () => {
        createComponent({ issuableType: TYPE_MERGE_REQUEST, canMerge: false, selected: true });

        expect(findIcon().classes('!gl-left-6')).toBe(true);
      });
    });

    it('does not render an icon when project member can merge', () => {
      createComponent({ issuableType: TYPE_MERGE_REQUEST, canMerge: true });

      expect(findIcon().exists()).toBe(false);
    });
  });
});
