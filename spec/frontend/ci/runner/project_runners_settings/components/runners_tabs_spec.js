import { shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';
import RunnersTabs from '~/ci/runner/project_runners_settings/components/runners_tabs.vue';
import RunnersTab from '~/ci/runner/project_runners_settings/components/runners_tab.vue';

const error = new Error('Test error');

describe('RunnersTabs', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(RunnersTabs, {
      propsData: {
        projectFullPath: 'group/project',
        ...props,
      },
      stubs: {
        GlTabs,
      },
    });
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findRunnerTabs = () => wrapper.findAllComponents(RunnersTab);
  const findRunnerTabAt = (i) => findRunnerTabs().at(i);

  beforeEach(() => {
    createComponent();
  });

  it('renders tabs container', () => {
    expect(findTabs().exists()).toBe(true);
  });

  it('renders the correct number of tabs', () => {
    expect(findRunnerTabs()).toHaveLength(3);
  });

  describe('Project tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTabAt(0).props()).toMatchObject({
        title: 'Project',
        runnerType: PROJECT_TYPE,
        projectFullPath: 'group/project',
      });
      expect(findRunnerTabAt(0).text()).toBe(
        'No project runners found, you can create one by selecting "New project runner".',
      );
    });

    it('emits an error event', () => {
      findRunnerTabAt(0).vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });
  });

  describe('Group tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTabAt(1).props()).toMatchObject({
        title: 'Group',
        runnerType: GROUP_TYPE,
        projectFullPath: 'group/project',
      });
      expect(findRunnerTabAt(1).text()).toBe('No group runners found.');
    });

    it('emits an error event', () => {
      findRunnerTabAt(1).vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });
  });

  describe('Instance tab', () => {
    it('renders the tab content', () => {
      expect(findRunnerTabAt(2).props()).toMatchObject({
        title: 'Instance',
        runnerType: INSTANCE_TYPE,
        projectFullPath: 'group/project',
      });
      expect(findRunnerTabAt(2).text()).toBe('No instance runners found.');
    });

    it('emits an error event', () => {
      findRunnerTabAt(2).vm.$emit('error', error);

      expect(wrapper.emitted().error[0]).toEqual([error]);
    });
  });
});
