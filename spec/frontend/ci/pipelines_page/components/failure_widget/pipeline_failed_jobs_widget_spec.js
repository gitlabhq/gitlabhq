import { GlButton } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
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
      stubs: { CrudComponent },
    });
  };

  const findFailedJobsButton = () => wrapper.findComponent(GlButton);
  const findFailedJobsList = () => wrapper.findAllComponents(FailedJobsList);
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);

  describe('when there are failed jobs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the show failed jobs button with correct count', () => {
      expect(findFailedJobsButton().exists()).toBe(true);
      expect(findFailedJobsButton().text()).toContain(`${defaultProps.failedJobsCount}`);
    });

    it('does not render the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(false);
    });
  });

  const CSS_BORDER_CLASSES = 'is-collapsed gl-border-white hover:gl-border-gray-100';

  describe('when the job button is clicked', () => {
    beforeEach(async () => {
      createComponent();
      await findFailedJobsButton().vm.$emit('click');
    });

    it('renders the failed jobs widget', () => {
      expect(findFailedJobsList().exists()).toBe(true);
    });

    it('removes the CSS border classes', () => {
      expect(findCrudComponent().attributes('class')).not.toContain(CSS_BORDER_CLASSES);
    });

    it('the failed jobs button has the correct "aria-expanded" attribute value', () => {
      expect(findFailedJobsButton().attributes('aria-expanded')).toBe('true');
    });
  });

  describe('when the job details are not expanded', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has the CSS border classes', () => {
      expect(findCrudComponent().attributes('class')).toContain(CSS_BORDER_CLASSES);
    });

    it('the failed jobs button has the correct "aria-expanded" attribute value', () => {
      expect(findFailedJobsButton().attributes('aria-expanded')).toBe('false');
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

  describe('"aria-controls" attribute', () => {
    it('is set and identifies the correct element', () => {
      createComponent();

      expect(findFailedJobsButton().attributes('aria-controls')).toBe(
        'pipeline-failed-jobs-widget',
      );
      expect(findCrudComponent().attributes('id')).toBe('pipeline-failed-jobs-widget');
    });
  });
});
