import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import WidgetFailedJobRow from '~/pipelines/components/pipelines_list/failure_widget/widget_failed_job_row.vue';

describe('WidgetFailedJobRow component', () => {
  let wrapper;

  const defaultProps = {
    job: {
      id: 'gid://gitlab/Ci::Build/5240',
      detailedStatus: {
        group: 'running',
        icon: 'icon_status_running',
      },
      name: 'my-job',
      stage: {
        name: 'build',
      },
      trace: {
        htmlSummary: '<h1>job log</h1>',
      },
      webpath: '/',
    },
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(WidgetFailedJobRow, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findArrowIcon = () => wrapper.findComponent(GlIcon);
  const findJobCiStatus = () => wrapper.findComponent(CiIcon);
  const findJobId = () => wrapper.findComponent(GlLink);
  const findHiddenJobLog = () => wrapper.findByTestId('log-is-hidden');
  const findVisibleJobLog = () => wrapper.findByTestId('log-is-visible');
  const findJobName = () => wrapper.findByText(defaultProps.job.name);
  const findRow = () => wrapper.findByTestId('widget-row');
  const findStageName = () => wrapper.findByText(defaultProps.job.stage.name);

  describe('ui', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the job name', () => {
      expect(findJobName().exists()).toBe(true);
    });

    it('renders the stage name', () => {
      expect(findStageName().exists()).toBe(true);
    });

    it('renders the job id as a link', () => {
      const jobId = getIdFromGraphQLId(defaultProps.job.id);

      expect(findJobId().exists()).toBe(true);
      expect(findJobId().text()).toContain(String(jobId));
    });

    it('renders the ci status badge', () => {
      expect(findJobCiStatus().exists()).toBe(true);
    });

    it('renders the right arrow', () => {
      expect(findArrowIcon().props().name).toBe('chevron-right');
    });

    it('does not renders the job lob', () => {
      expect(findHiddenJobLog().exists()).toBe(true);
      expect(findVisibleJobLog().exists()).toBe(false);
    });
  });

  describe('Job log', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when clicking on the row', () => {
      beforeEach(async () => {
        await findRow().trigger('click');
      });

      describe('while collapsed', () => {
        it('expands the job log', () => {
          expect(findHiddenJobLog().exists()).toBe(false);
          expect(findVisibleJobLog().exists()).toBe(true);
        });

        it('renders the down arrow', () => {
          expect(findArrowIcon().props().name).toBe('chevron-down');
        });

        it('renders the received html', () => {
          expect(findVisibleJobLog().html()).toContain(defaultProps.job.trace.htmlSummary);
        });
      });

      describe('while expanded', () => {
        it('collapes the job log', async () => {
          expect(findHiddenJobLog().exists()).toBe(false);
          expect(findVisibleJobLog().exists()).toBe(true);

          await findRow().trigger('click');

          expect(findHiddenJobLog().exists()).toBe(true);
          expect(findVisibleJobLog().exists()).toBe(false);
        });

        it('renders the right arrow', async () => {
          expect(findArrowIcon().props().name).toBe('chevron-down');

          await findRow().trigger('click');

          expect(findArrowIcon().props().name).toBe('chevron-right');
        });
      });
    });

    describe('when clicking on a link element within the row', () => {
      it('does not expands/collapse the job log', async () => {
        expect(findHiddenJobLog().exists()).toBe(true);
        expect(findVisibleJobLog().exists()).toBe(false);
        expect(findArrowIcon().props().name).toBe('chevron-right');

        await findJobId().vm.$emit('click');

        expect(findHiddenJobLog().exists()).toBe(true);
        expect(findVisibleJobLog().exists()).toBe(false);
        expect(findArrowIcon().props().name).toBe('chevron-right');
      });
    });
  });
});
