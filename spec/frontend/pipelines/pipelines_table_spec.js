import { GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelineOperations from '~/pipelines/components/pipelines_list/pipeline_operations.vue';
import PipelineTriggerer from '~/pipelines/components/pipelines_list/pipeline_triggerer.vue';
import PipelineUrl from '~/pipelines/components/pipelines_list/pipeline_url.vue';
import PipelinesStatusBadge from '~/pipelines/components/pipelines_list/pipelines_status_badge.vue';
import PipelinesTable from '~/pipelines/components/pipelines_list/pipelines_table.vue';
import PipelinesTimeago from '~/pipelines/components/pipelines_list/time_ago.vue';
import CommitComponent from '~/vue_shared/components/commit.vue';

describe('Pipelines Table', () => {
  let pipeline;
  let wrapper;

  const jsonFixtureName = 'pipelines/pipelines.json';

  const defaultProps = {
    pipelines: [],
    viewType: 'root',
  };

  const createComponent = (props = defaultProps, flagState = false) => {
    wrapper = extendedWrapper(
      mount(PipelinesTable, {
        propsData: props,
        provide: {
          glFeatures: {
            newPipelinesTable: flagState,
          },
        },
      }),
    );
  };

  const findRows = () => wrapper.findAll('.commit.gl-responsive-table-row');
  const findGlTable = () => wrapper.findComponent(GlTable);
  const findStatusBadge = () => wrapper.findComponent(PipelinesStatusBadge);
  const findPipelineInfo = () => wrapper.findComponent(PipelineUrl);
  const findTriggerer = () => wrapper.findComponent(PipelineTriggerer);
  const findCommit = () => wrapper.findComponent(CommitComponent);
  const findTimeAgo = () => wrapper.findComponent(PipelinesTimeago);
  const findActions = () => wrapper.findComponent(PipelineOperations);

  const findLegacyTable = () => wrapper.findByTestId('legacy-ci-table');
  const findTableRows = () => wrapper.findAll('[data-testid="pipeline-table-row"]');
  const findStatusTh = () => wrapper.findByTestId('status-th');
  const findPipelineTh = () => wrapper.findByTestId('pipeline-th');
  const findTriggererTh = () => wrapper.findByTestId('triggerer-th');
  const findCommitTh = () => wrapper.findByTestId('commit-th');
  const findStagesTh = () => wrapper.findByTestId('stages-th');
  const findTimeAgoTh = () => wrapper.findByTestId('timeago-th');
  const findActionsTh = () => wrapper.findByTestId('actions-th');

  beforeEach(() => {
    const { pipelines } = getJSONFixture(jsonFixtureName);
    pipeline = pipelines.find((p) => p.user !== null && p.commit !== null);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('table with feature flag off', () => {
    describe('renders the table correctly', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should render a table', () => {
        expect(wrapper.classes()).toContain('ci-table');
      });

      it('should render table head with correct columns', () => {
        expect(wrapper.find('.table-section.js-pipeline-status').text()).toEqual('Status');

        expect(wrapper.find('.table-section.js-pipeline-info').text()).toEqual('Pipeline');

        expect(wrapper.find('.table-section.js-pipeline-commit').text()).toEqual('Commit');

        expect(wrapper.find('.table-section.js-pipeline-stages').text()).toEqual('Stages');
      });
    });

    describe('without data', () => {
      it('should render an empty table', () => {
        createComponent();

        expect(findRows()).toHaveLength(0);
      });
    });

    describe('with data', () => {
      it('should render rows', () => {
        createComponent({ pipelines: [pipeline], viewType: 'root' });

        expect(findRows()).toHaveLength(1);
      });
    });
  });

  describe('table with feature flag on', () => {
    beforeEach(() => {
      createComponent({ pipelines: [pipeline], viewType: 'root' }, true);
    });

    it('displays new table', () => {
      expect(findGlTable().exists()).toBe(true);
      expect(findLegacyTable().exists()).toBe(false);
    });

    it('should render table head with correct columns', () => {
      expect(findStatusTh().text()).toBe('Status');
      expect(findPipelineTh().text()).toBe('Pipeline');
      expect(findTriggererTh().text()).toBe('Triggerer');
      expect(findCommitTh().text()).toBe('Commit');
      expect(findStagesTh().text()).toBe('Stages');
      expect(findTimeAgoTh().text()).toBe('Duration');

      // last column should have no text in th
      expect(findActionsTh().text()).toBe('');
    });

    it('should display a table row', () => {
      expect(findTableRows()).toHaveLength(1);
    });

    describe('status cell', () => {
      it('should render a status badge', () => {
        expect(findStatusBadge().exists()).toBe(true);
      });

      it('should render status badge with correct path', () => {
        expect(findStatusBadge().attributes('href')).toBe(pipeline.path);
      });
    });

    describe('pipeline cell', () => {
      it('should render pipeline information', () => {
        expect(findPipelineInfo().exists()).toBe(true);
      });

      it('should display the pipeline id', () => {
        expect(findPipelineInfo().text()).toContain(`#${pipeline.id}`);
      });
    });

    describe('triggerer cell', () => {
      it('should render the pipeline triggerer', () => {
        expect(findTriggerer().exists()).toBe(true);
      });
    });

    describe('commit cell', () => {
      it('should render commit information', () => {
        expect(findCommit().exists()).toBe(true);
      });

      it('should display and link to commit', () => {
        expect(findCommit().text()).toContain(pipeline.commit.short_id);
        expect(findCommit().props('commitUrl')).toBe(pipeline.commit.commit_path);
      });

      it('should display the commit author', () => {
        expect(findCommit().props('author')).toEqual(pipeline.commit.author);
      });
    });

    describe('duration cell', () => {
      it('should render duration information', () => {
        expect(findTimeAgo().exists()).toBe(true);
      });
    });

    describe('operations cell', () => {
      it('should render pipeline operations', () => {
        expect(findActions().exists()).toBe(true);
      });
    });
  });
});
