import { GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTypeTabs from '~/runner/components/runner_type_tabs.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/runner/constants';

const mockSearch = { runnerType: null, filters: [], pagination: { page: 1 }, sort: 'CREATED_DESC' };

describe('RunnerTypeTabs', () => {
  let wrapper;

  const findTabs = () => wrapper.findAll(GlTab);
  const findActiveTab = () =>
    findTabs()
      .filter((tab) => tab.attributes('active') === 'true')
      .at(0);
  const getTabsTitles = () => findTabs().wrappers.map((tab) => tab.text());

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = shallowMount(RunnerTypeTabs, {
      propsData: {
        value: mockSearch,
        ...props,
      },
      stubs: {
        GlTab,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Renders all options to filter runners by default', () => {
    expect(getTabsTitles()).toEqual(['All', 'Instance', 'Group', 'Project']);
  });

  it('Renders fewer options to filter runners', () => {
    createComponent({
      props: {
        runnerTypes: [GROUP_TYPE, PROJECT_TYPE],
      },
    });

    expect(getTabsTitles()).toEqual(['All', 'Group', 'Project']);
  });

  it('"All" is selected by default', () => {
    expect(findActiveTab().text()).toBe('All');
  });

  it('Another tab can be preselected by the user', () => {
    createComponent({
      props: {
        value: {
          ...mockSearch,
          runnerType: INSTANCE_TYPE,
        },
      },
    });

    expect(findActiveTab().text()).toBe('Instance');
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

      expect(findActiveTab().text()).toBe('Group');
    });
  });

  describe('When using a custom slot', () => {
    const mockContent = 'content';

    beforeEach(() => {
      createComponent({
        scopedSlots: {
          title: `
          <span>
            {{props.tab.title}} ${mockContent}
          </span>`,
        },
      });
    });

    it('Renders tabs with additional information', () => {
      expect(findTabs().wrappers.map((tab) => tab.text())).toEqual([
        `All ${mockContent}`,
        `Instance ${mockContent}`,
        `Group ${mockContent}`,
        `Project ${mockContent}`,
      ]);
    });
  });
});
