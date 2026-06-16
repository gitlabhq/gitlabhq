import { GlButton, GlFormCheckbox, GlAlert, GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import UserExclusionInclusion from '~/integrations/gitlab_slack_application/components/user_exclusion_inclusion.vue';

describe('UserExclusionInclusion', () => {
  let wrapper;

  const mockUsers = [
    { id: 1, name: 'John Doe', username: 'johndoe' },
    { id: 2, name: 'Jane Smith', username: 'janesmith' },
    { id: 3, name: 'Bot User', username: 'bot-user' },
  ];

  const createComponent = (props = {}) => {
    wrapper = shallowMount(UserExclusionInclusion, {
      propsData: {
        users: mockUsers,
        ...props,
      },
      stubs: {
        GlButton,
        GlFormCheckbox,
        GlAlert,
        GlCollapsibleListbox,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('renders the component', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('displays the title', () => {
      expect(wrapper.text()).toContain('Configure Users for Slack Notifications');
    });

    it('displays inclusion list section', () => {
      expect(wrapper.text()).toContain('Include Users');
    });

    it('displays exclusion list section', () => {
      expect(wrapper.text()).toContain('Exclude Users');
    });

    it('displays global filter checkbox', () => {
      expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(true);
    });

    it('renders save button', () => {
      expect(wrapper.findComponent(GlButton).exists()).toBe(true);
    });
  });

  describe('user items computation', () => {
    it('converts users to dropdown items', () => {
      expect(wrapper.vm.userItems).toEqual([
        { value: 1, text: 'John Doe (@johndoe)' },
        { value: 2, text: 'Jane Smith (@janesmith)' },
        { value: 3, text: 'Bot User (@bot-user)' },
      ]);
    });
  });

  describe('configuration management', () => {
    it('allows adding users to inclusion list', async () => {
      wrapper.vm.inclusionList = [1, 2];
      await nextTick();
      expect(wrapper.vm.inclusionList).toEqual([1, 2]);
    });

    it('allows adding users to exclusion list', async () => {
      wrapper.vm.exclusionList = [3];
      await nextTick();
      expect(wrapper.vm.exclusionList).toEqual([3]);
    });

    it('toggles global filter setting', async () => {
      wrapper.vm.isGlobalFilter = false;
      await nextTick();
      expect(wrapper.vm.isGlobalFilter).toBe(false);
    });
  });

  describe('saving configuration', () => {
    it('shows success message after saving', async () => {
      await wrapper.vm.saveConfiguration();
      await nextTick();
      expect(wrapper.vm.successMessage).not.toBe('');
    });
  });

  describe('reset functionality', () => {
    it('clears all selections on reset', async () => {
      wrapper.vm.inclusionList = [1];
      wrapper.vm.exclusionList = [2];
      await nextTick();

      wrapper.vm.resetForm();
      await nextTick();

      expect(wrapper.vm.inclusionList).toEqual([]);
      expect(wrapper.vm.exclusionList).toEqual([]);
    });
  });
});
