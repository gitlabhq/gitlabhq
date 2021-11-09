import { GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTypeTabs from '~/runner/components/runner_type_tabs.vue';
import { INSTANCE_TYPE, GROUP_TYPE } from '~/runner/constants';

const mockSearch = { runnerType: null, filters: [], pagination: { page: 1 }, sort: 'CREATED_DESC' };

describe('RunnerTypeTabs', () => {
  let wrapper;

  const findTabs = () => wrapper.findAll(GlTab);
  const findActiveTab = () =>
    findTabs()
      .filter((tab) => tab.attributes('active') === 'true')
      .at(0);

  const createComponent = ({ value = mockSearch } = {}) => {
    wrapper = shallowMount(RunnerTypeTabs, {
      propsData: {
        value,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Renders options to filter runners', () => {
    expect(findTabs().wrappers.map((tab) => tab.attributes('title'))).toEqual([
      'All',
      'Instance',
      'Group',
      'Project',
    ]);
  });

  it('"All" is selected by default', () => {
    expect(findActiveTab().attributes('title')).toBe('All');
  });

  it('Another tab can be preselected by the user', () => {
    createComponent({
      value: {
        ...mockSearch,
        runnerType: INSTANCE_TYPE,
      },
    });

    expect(findActiveTab().attributes('title')).toBe('Instance');
  });

  describe('When the user selects a tab', () => {
    const emittedValue = () => wrapper.emitted('input')[0][0];

    beforeEach(() => {
      findTabs().at(2).vm.$emit('click');
    });

    it(`Runner type is emitted`, () => {
      expect(emittedValue()).toEqual({
        ...mockSearch,
        runnerType: GROUP_TYPE,
      });
    });

    it('Runner type is selected', async () => {
      const newValue = emittedValue();
      await wrapper.setProps({ value: newValue });

      expect(findActiveTab().attributes('title')).toBe('Group');
    });
  });
});
