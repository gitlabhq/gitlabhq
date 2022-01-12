import { GlButton, GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BridgeSidebar from '~/jobs/bridge/components/sidebar.vue';
import CommitBlock from '~/jobs/components/commit_block.vue';
import { mockCommit, mockJob } from '../mock_data';

describe('Bridge Sidebar', () => {
  let wrapper;

  const createComponent = ({ featureFlag } = {}) => {
    wrapper = shallowMount(BridgeSidebar, {
      provide: {
        glFeatures: {
          triggerJobRetryAction: featureFlag,
        },
      },
      propsData: {
        bridgeJob: mockJob,
        commit: mockCommit,
      },
    });
  };

  const findJobTitle = () => wrapper.find('h4');
  const findCommitBlock = () => wrapper.findComponent(CommitBlock);
  const findRetryDropdown = () => wrapper.find(GlDropdown);
  const findToggleBtn = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders job name', () => {
      expect(findJobTitle().text()).toBe(mockJob.name);
    });

    it('renders commit information', () => {
      expect(findCommitBlock().exists()).toBe(true);
    });
  });

  describe('sidebar expansion', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits toggle sidebar event on button click', async () => {
      expect(wrapper.emitted('toggleSidebar')).toBe(undefined);

      findToggleBtn().vm.$emit('click');

      expect(wrapper.emitted('toggleSidebar')).toHaveLength(1);
    });
  });

  describe('retry action', () => {
    describe('when feature flag is ON', () => {
      beforeEach(() => {
        createComponent({ featureFlag: true });
      });

      it('renders retry dropdown', () => {
        expect(findRetryDropdown().exists()).toBe(true);
      });
    });

    describe('when feature flag is OFF', () => {
      it('does not render retry dropdown', () => {
        createComponent({ featureFlag: false });

        expect(findRetryDropdown().exists()).toBe(false);
      });
    });
  });
});
