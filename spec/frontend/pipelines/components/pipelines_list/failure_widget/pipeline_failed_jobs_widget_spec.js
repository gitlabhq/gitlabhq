import { GlIcon, GlPopover } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineFailedJobsWidget from '~/pipelines/components/pipelines_list/failure_widget/pipeline_failed_jobs_widget.vue';

describe('PipelineFailedJobsWidget component', () => {
  let wrapper;

  const defaultProps = {
    pipelinePath: '/pipelines/1',
  };

  const defaultProvide = {
    fullPath: 'namespace/project/',
  };

  const createComponent = ({ props = {}, provide } = {}) => {
    wrapper = shallowMountExtended(PipelineFailedJobsWidget, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const findFailedJobsButton = () => wrapper.findByText('Show failed jobs');
  const findInfoIcon = () => wrapper.findComponent(GlIcon);
  const findInfoPopover = () => wrapper.findComponent(GlPopover);

  describe('ui', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the show failed jobs button', () => {
      expect(findFailedJobsButton().exists()).toBe(true);
      expect(findFailedJobsButton().text()).toBe('Show failed jobs');
    });

    it('renders the info icon', () => {
      expect(findInfoIcon().exists()).toBe(true);
    });

    it('renders the info popover', () => {
      expect(findInfoPopover().exists()).toBe(true);
    });
  });
});
