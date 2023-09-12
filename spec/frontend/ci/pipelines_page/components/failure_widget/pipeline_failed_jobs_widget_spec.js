import { GlButton, GlCard, GlIcon, GlPopover } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineFailedJobsWidget from '~/ci/pipelines_page/components/failure_widget/pipeline_failed_jobs_widget.vue';
import FailedJobsList from '~/ci/pipelines_page/components/failure_widget/failed_jobs_list.vue';

jest.mock('~/alert');

describe('PipelineFailedJobsWidget component', () => {
  let wrapper;

  const defaultProps = {
    failedJobsCount: 4,
    isPipelineActive: false,
    pipelineIid: 1,
    pipelinePath: '/pipelines/1',
    projectPath: 'namespace/project/',
  };

  const defaultProvide = {
    fullPath: 'namespace/project/',
  };

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(PipelineFailedJobsWidget, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: { GlCard },
    });
  };

  const findFailedJobsCard = () => wrapper.findByTestId('failed-jobs-card');
  const findFailedJobsButton = () => wrapper.findComponent(GlButton);
  const findFailedJobsList = () => wrapper.findAllComponents(FailedJobsList);
  const findInfoIcon = () => wrapper.findComponent(GlIcon);
  const findInfoPopover = () => wrapper.findComponent(GlPopover);

  describe('when there are no failed jobs', () => {
    beforeEach(() => {
      createComponent({ props: { failedJobsCount: 0 } });
    });

    it('renders the show failed jobs button with a count of 0', () => {
      expect(findFailedJobsButton().exists()).toBe(true);
      expect(findFailedJobsButton().text()).toBe('Failed jobs (0)');
    });
  });

  describe('when there are failed jobs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the show failed jobs button with correct count', () => {
      expect(findFailedJobsButton().exists()).toBe(true);
      expect(findFailedJobsButton().text()).toBe(`Failed jobs (${defaultProps.failedJobsCount})`);
    });

    it('renders the info icon', () => {
      expect(findInfoIcon().exists()).toBe(true);
    });

    it('renders the info popover', () => {
      expect(findInfoPopover().exists()).toBe(true);
    });

    it('does not render the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(false);
    });
  });

  describe('when the job button is clicked', () => {
    beforeEach(async () => {
      createComponent();
      await findFailedJobsButton().vm.$emit('click');
    });

    it('renders the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(true);
    });

    it('removes the CSS border classes', () => {
      expect(findFailedJobsCard().attributes('class')).not.toContain(
        'gl-border-white gl-hover-border-gray-100',
      );
    });
  });

  describe('when the job details are not expanded', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has the CSS border classes', () => {
      expect(findFailedJobsCard().attributes('class')).toContain(
        'gl-border-white gl-hover-border-gray-100',
      );
    });
  });

  describe('when the job count changes', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('from the prop', () => {
      it('updates the job count', async () => {
        const newJobCount = 12;

        expect(findFailedJobsButton().text()).toContain(String(defaultProps.failedJobsCount));

        await wrapper.setProps({ failedJobsCount: newJobCount });

        expect(findFailedJobsButton().text()).toContain(String(newJobCount));
      });
    });

    describe('from the event', () => {
      beforeEach(async () => {
        await findFailedJobsButton().vm.$emit('click');
      });

      it('updates the job count', async () => {
        const newJobCount = 12;

        expect(findFailedJobsButton().text()).toContain(String(defaultProps.failedJobsCount));

        await findFailedJobsList().at(0).vm.$emit('failed-jobs-count', newJobCount);

        expect(findFailedJobsButton().text()).toContain(String(newJobCount));
      });
    });
  });
});
