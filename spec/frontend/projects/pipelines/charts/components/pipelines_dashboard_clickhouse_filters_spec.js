import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import PipelinesDashboardClickhouseFilters from '~/projects/pipelines/charts/components/pipelines_dashboard_clickhouse_filters.vue';
import BranchCollapsibleListbox from '~/projects/pipelines/charts/components/branch_collapsible_listbox.vue';

jest.mock('~/alert');

const projectPath = 'gitlab-org/gitlab';
const defaultBranch = 'main';
const projectBranchCount = 99;

describe('PipelinesDashboardClickhouseFilters', () => {
  let wrapper;

  const findCollapsibleListbox = (id) =>
    wrapper.findAllComponents(GlCollapsibleListbox).wrappers.find((w) => w.attributes('id') === id);
  const findBranchCollapsibleListbox = () => wrapper.findComponent(BranchCollapsibleListbox);

  const createComponent = ({ props, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(PipelinesDashboardClickhouseFilters, {
      propsData: {
        defaultBranch,
        projectPath,
        projectBranchCount,
        ...props,
      },
    });
  };

  describe('input', () => {
    beforeEach(() => {
      createComponent({
        props: { value: { source: 'PUSH', dateRange: '30d', branch: 'my-branch-0' } },
      });
    });

    it('sets values, and does not emit @input', () => {
      expect(findCollapsibleListbox('pipeline-source').props('selected')).toBe('PUSH');
      expect(findBranchCollapsibleListbox().props('selected')).toBe('my-branch-0');
      expect(findCollapsibleListbox('date-range').props('selected')).toBe('30d');

      expect(wrapper.emitted('input')).toBeUndefined();
    });

    it('reacts to changes in value, and does not emit @input', async () => {
      wrapper.setProps({ value: { source: 'SCHEDULE', dateRange: '180d', branch: 'my-branch-1' } });
      await nextTick();

      expect(findCollapsibleListbox('pipeline-source').props('selected')).toBe('SCHEDULE');
      expect(findBranchCollapsibleListbox().props('selected')).toBe('my-branch-1');
      expect(findCollapsibleListbox('date-range').props('selected')).toBe('180d');

      expect(wrapper.emitted('input')).toBeUndefined();
    });
  });

  describe('source', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows options', () => {
      const sources = findCollapsibleListbox('pipeline-source')
        .props('items')
        .map(({ text }) => text);

      expect(sources).toEqual([
        'Any source',
        'Push',
        'Schedule',
        'Merge Request Event',
        'Web',
        'Trigger',
        'API',
        'External',
        'Pipeline',
        'Chat',
        'Web IDE',
        'External Pull Request Event',
        'Parent Pipeline',
        'On-Demand DAST Scan',
        'On-Demand DAST Validation',
        'Scheduled Scan Execution Policy',
        'Container Registry Push',
        'Duo Agent Platform',
        'Scheduled Pipeline Execution Policy',
        'Unknown',
      ]);
    });

    it('is "Any" by default', () => {
      expect(findCollapsibleListbox('pipeline-source').props('selected')).toBe(null);
    });

    it('sets selected value', () => {
      createComponent({
        props: {
          value: {
            source: 'PUSH',
          },
        },
      });

      expect(findCollapsibleListbox('pipeline-source').props('selected')).toBe('PUSH');
    });

    it('does not set invalid value as selected', () => {
      createComponent({
        props: {
          value: {
            source: 'NOT_AN_OPTION',
          },
        },
      });

      expect(findCollapsibleListbox('pipeline-source').props('selected')).toBe(null);
    });

    it('emits when an option is selected', async () => {
      findCollapsibleListbox('pipeline-source').vm.$emit('select', 'PUSH');

      await nextTick();

      expect(wrapper.emitted('input')[0][0]).toEqual({
        branch: null,
        dateRange: '7d',
        source: 'PUSH',
      });
    });
  });

  describe('branch', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows listbox with default branch as default value', () => {
      expect(findBranchCollapsibleListbox().props()).toMatchObject({
        selected: null,
        defaultBranch,
        projectPath,
        projectBranchCount,
      });
    });

    it('is no branch by default', () => {
      expect(findBranchCollapsibleListbox().props('selected')).toBe(null);
    });

    it('sets selected value', () => {
      createComponent({
        props: {
          value: {
            branch: 'my-branch-0',
          },
        },
      });

      expect(findBranchCollapsibleListbox().props('selected')).toBe('my-branch-0');
    });

    it('emits when an option is selected', async () => {
      findBranchCollapsibleListbox().vm.$emit('select', 'my-branch-1');

      await nextTick();

      expect(wrapper.emitted('input')[0][0]).toEqual({
        branch: 'my-branch-1',
        dateRange: '7d',
        source: null,
      });
    });
  });

  describe('date range', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows options', () => {
      const ranges = findCollapsibleListbox('date-range')
        .props('items')
        .map(({ text }) => text);

      expect(ranges).toEqual(['Last week', 'Last 30 days', 'Last 90 days', 'Last 180 days']);
    });

    it('is "Last 7 days" by default', () => {
      expect(findCollapsibleListbox('date-range').props('selected')).toBe('7d');
    });

    it('does not set invalid value as selected', () => {
      createComponent({
        props: {
          value: {
            source: 'NOT_AN_OPTION',
          },
        },
      });

      expect(findCollapsibleListbox('date-range').props('selected')).toBe('7d');
    });

    it('emits when an option is selected', async () => {
      findCollapsibleListbox('date-range').vm.$emit('select', '90d');

      await nextTick();

      expect(wrapper.emitted('input')[0][0]).toEqual({
        dateRange: '90d',
        branch: null,
        source: null,
      });
    });
  });
});
