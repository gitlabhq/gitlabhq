import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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

  describe('ui', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the job name', () => {
      expect(wrapper.html()).toContain(defaultProps.job.name);
    });
  });
});
