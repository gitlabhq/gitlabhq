import { GlTruncate, GlLink, GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentJob from '~/environments/environment_details/components/deployment_job.vue';

describe('app/assets/javascripts/environments/environment_details/components/deployment_job.vue', () => {
  const jobData = {
    webPath: 'http://example.com',
    label: 'example job',
  };
  let wrapper;

  const createWrapper = ({ job }) => {
    return mountExtended(DeploymentJob, {
      propsData: {
        job,
      },
    });
  };

  describe('when the job data exists', () => {
    beforeEach(() => {
      wrapper = createWrapper({ job: jobData });
    });

    it('should render a link with a correct href', () => {
      const jobLink = wrapper.findComponent(GlLink);
      expect(jobLink.exists()).toBe(true);
      expect(jobLink.attributes().href).toBe(jobData.webPath);
    });
    it('should render a truncated label', () => {
      const truncatedLabel = wrapper.findComponent(GlTruncate);
      expect(truncatedLabel.exists()).toBe(true);
      expect(truncatedLabel.props().text).toBe(jobData.label);
    });
  });

  describe('when the job data does not exist', () => {
    beforeEach(() => {
      wrapper = createWrapper({ job: null });
    });

    it('should render a badge with the text "API"', () => {
      const badge = wrapper.findComponent(GlBadge);
      expect(badge.exists()).toBe(true);
      expect(badge.props().variant).toBe('info');
      expect(badge.text()).toBe('API');
    });
  });
});
