import { shallowMount, mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import { trimText } from 'helpers/text_helper';
import { SUCCESS } from '~/vue_merge_request_widget/constants';
import PipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import PipelineStage from '~/pipelines/components/pipelines_list/stage.vue';
import mockData from '../mock_data';

describe('MRWidgetPipeline', () => {
  let wrapper;

  const defaultProps = {
    pipeline: mockData.pipeline,
    ciStatus: SUCCESS,
    hasCi: true,
    mrTroubleshootingDocsPath: 'help',
    ciTroubleshootingDocsPath: 'ci-help',
  };

  const ciErrorMessage =
    'Could not retrieve the pipeline status. For troubleshooting steps, read the documentation.';
  const monitoringMessage = 'Checking pipeline status.';

  const findCIErrorMessage = () => wrapper.find('[data-testid="ci-error-message"]');
  const findPipelineID = () => wrapper.find('[data-testid="pipeline-id"]');
  const findPipelineInfoContainer = () => wrapper.find('[data-testid="pipeline-info-container"]');
  const findCommitLink = () => wrapper.find('[data-testid="commit-link"]');
  const findPipelineGraph = () => wrapper.find('[data-testid="widget-mini-pipeline-graph"]');
  const findAllPipelineStages = () => wrapper.findAll(PipelineStage);
  const findPipelineCoverage = () => wrapper.find('[data-testid="pipeline-coverage"]');
  const findPipelineCoverageDelta = () => wrapper.find('[data-testid="pipeline-coverage-delta"]');
  const findMonitoringPipelineMessage = () =>
    wrapper.find('[data-testid="monitoring-pipeline-message"]');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const createWrapper = (props, mountFn = shallowMount) => {
    wrapper = mountFn(PipelineComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('computed', () => {
    describe('hasPipeline', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('should return true when there is a pipeline', () => {
        expect(wrapper.vm.hasPipeline).toBe(true);
      });

      it('should return false when there is no pipeline', async () => {
        wrapper.setProps({ pipeline: {} });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.hasPipeline).toBe(false);
      });
    });

    describe('hasCIError', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('should return false when there is no CI error', () => {
        expect(wrapper.vm.hasCIError).toBe(false);
      });

      it('should return true when there is a pipeline, but no ci status', async () => {
        wrapper.setProps({ ciStatus: null });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.hasCIError).toBe(true);
      });
    });

    describe('coverageDeltaClass', () => {
      beforeEach(() => {
        createWrapper({ pipelineCoverageDelta: '0' });
      });

      it('should return no class if there is no coverage change', async () => {
        expect(wrapper.vm.coverageDeltaClass).toBe('');
      });

      it('should return text-success if the coverage increased', async () => {
        wrapper.setProps({ pipelineCoverageDelta: '10' });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.coverageDeltaClass).toBe('text-success');
      });

      it('should return text-danger if the coverage decreased', async () => {
        wrapper.setProps({ pipelineCoverageDelta: '-12' });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.coverageDeltaClass).toBe('text-danger');
      });
    });
  });

  describe('rendered output', () => {
    beforeEach(() => {
      createWrapper({ ciStatus: null }, mount);
    });

    it('should render CI error if there is a pipeline, but no status', async () => {
      expect(findCIErrorMessage().text()).toBe(ciErrorMessage);
    });

    it('should render a loading state when no pipeline is found', async () => {
      wrapper.setProps({
        pipeline: {},
        hasCi: false,
        pipelineMustSucceed: true,
      });

      await wrapper.vm.$nextTick();

      expect(findMonitoringPipelineMessage().text()).toBe(monitoringMessage);
      expect(findLoadingIcon().exists()).toBe(true);
    });

    describe('with a pipeline', () => {
      beforeEach(() => {
        createWrapper(
          {
            pipelineCoverageDelta: mockData.pipelineCoverageDelta,
          },
          mount,
        );
      });

      it('should render pipeline ID', () => {
        expect(
          findPipelineID()
            .text()
            .trim(),
        ).toBe(`#${mockData.pipeline.id}`);
      });

      it('should render pipeline status and commit id', () => {
        expect(findPipelineInfoContainer().text()).toMatch(mockData.pipeline.details.status.label);

        expect(
          findCommitLink()
            .text()
            .trim(),
        ).toBe(mockData.pipeline.commit.short_id);

        expect(findCommitLink().attributes('href')).toBe(mockData.pipeline.commit.commit_path);
      });

      it('should render pipeline graph', () => {
        expect(findPipelineGraph().exists()).toBe(true);
        expect(findAllPipelineStages().length).toBe(mockData.pipeline.details.stages.length);
      });

      it('should render coverage information', () => {
        expect(findPipelineCoverage().text()).toMatch(`Coverage ${mockData.pipeline.coverage}%`);
      });

      it('should render pipeline coverage delta information', () => {
        expect(findPipelineCoverageDelta().exists()).toBe(true);
        expect(findPipelineCoverageDelta().text()).toBe(`(${mockData.pipelineCoverageDelta}%)`);
      });
    });

    describe('without commit path', () => {
      beforeEach(() => {
        const mockCopy = JSON.parse(JSON.stringify(mockData));
        delete mockCopy.pipeline.commit;

        createWrapper({}, mount);
      });

      it('should render pipeline ID', () => {
        expect(
          findPipelineID()
            .text()
            .trim(),
        ).toBe(`#${mockData.pipeline.id}`);
      });

      it('should render pipeline status', () => {
        expect(findPipelineInfoContainer().text()).toMatch(mockData.pipeline.details.status.label);
      });

      it('should render pipeline graph', () => {
        expect(findPipelineGraph().exists()).toBe(true);
        expect(findAllPipelineStages().length).toBe(mockData.pipeline.details.stages.length);
      });

      it('should render coverage information', () => {
        expect(findPipelineCoverage().text()).toMatch(`Coverage ${mockData.pipeline.coverage}%`);
      });
    });

    describe('without coverage', () => {
      beforeEach(() => {
        const mockCopy = JSON.parse(JSON.stringify(mockData));
        delete mockCopy.pipeline.coverage;

        createWrapper(
          {
            pipeline: mockCopy.pipeline,
          },
          mount,
        );
      });

      it('should not render a coverage component', () => {
        expect(findPipelineCoverage().exists()).toBe(false);
      });
    });

    describe('without a pipeline graph', () => {
      beforeEach(() => {
        const mockCopy = JSON.parse(JSON.stringify(mockData));
        delete mockCopy.pipeline.details.stages;

        createWrapper({
          pipeline: mockCopy.pipeline,
        });
      });

      it('should not render a pipeline graph', () => {
        expect(findPipelineGraph().exists()).toBe(false);
      });
    });

    describe('for each type of pipeline', () => {
      let pipeline;

      beforeEach(() => {
        ({ pipeline } = JSON.parse(JSON.stringify(mockData)));

        pipeline.details.name = 'Pipeline';
        pipeline.merge_request_event_type = undefined;
        pipeline.ref.tag = false;
        pipeline.ref.branch = false;
      });

      const factory = () => {
        createWrapper({
          pipeline,
          sourceBranchLink: mockData.source_branch_link,
        });
      };

      describe('for a branch pipeline', () => {
        it('renders a pipeline widget that reads "Pipeline <ID> <status> for <SHA> on <branch>"', () => {
          pipeline.ref.branch = true;

          factory();

          const expected = `Pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id} on ${mockData.source_branch_link}`;
          const actual = trimText(findPipelineInfoContainer().text());

          expect(actual).toBe(expected);
        });
      });

      describe('for a tag pipeline', () => {
        it('renders a pipeline widget that reads "Pipeline <ID> <status> for <SHA> on <branch>"', () => {
          pipeline.ref.tag = true;

          factory();

          const expected = `Pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
          const actual = trimText(findPipelineInfoContainer().text());

          expect(actual).toBe(expected);
        });
      });

      describe('for a detached merge request pipeline', () => {
        it('renders a pipeline widget that reads "Detached merge request pipeline <ID> <status> for <SHA>"', () => {
          pipeline.details.name = 'Detached merge request pipeline';
          pipeline.merge_request_event_type = 'detached';

          factory();

          const expected = `Detached merge request pipeline #${pipeline.id} ${pipeline.details.status.label} for ${pipeline.commit.short_id}`;
          const actual = trimText(findPipelineInfoContainer().text());

          expect(actual).toBe(expected);
        });
      });
    });
  });
});
