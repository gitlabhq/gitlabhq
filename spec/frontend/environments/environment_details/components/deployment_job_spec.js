import { shallowMount } from '@vue/test-utils';
import { GlTruncate, GlLink, GlBadge, GlIcon } from '@gitlab/ui';
import DeploymentJob from '~/environments/environment_details/components/deployment_job.vue';

describe('DeploymentJob', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    return shallowMount(DeploymentJob, {
      propsData: props,
      stubs: {
        GlTruncate,
        GlIcon,
      },
    });
  };

  const findGlLink = () => wrapper.findComponent(GlLink);
  const findTruncatedLabel = () => wrapper.findComponent(GlTruncate);
  const findPipelineIcon = () => wrapper.findComponent(GlIcon);
  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('with job data', () => {
    const defaultJob = {
      label: 'example job',
    };
    const webPath = 'path/to/job';

    describe('with job path', () => {
      beforeEach(() => {
        wrapper = createWrapper({
          job: {
            ...defaultJob,
            webPath,
          },
        });
      });

      it('renders a link with correct href', () => {
        expect(findGlLink().attributes('href')).toBe(webPath);
      });

      it('passes job label to truncate component', () => {
        expect(findTruncatedLabel().props('text')).toBe(defaultJob.label);
      });
    });

    describe('without job path', () => {
      beforeEach(() => {
        wrapper = createWrapper({ job: defaultJob });
      });

      it('renders job label without link', () => {
        expect(findGlLink().exists()).toBe(false);
        expect(findTruncatedLabel().props('text')).toBe(defaultJob.label);
      });
    });

    describe('with pipeline information', () => {
      const pipeline = {
        path: 'path/to/pipeline',
        label: '#123',
      };

      beforeEach(() => {
        wrapper = createWrapper({
          job: {
            ...defaultJob,
            pipeline,
          },
        });
      });

      it('renders pipeline link with correct attributes', () => {
        expect(findGlLink().attributes('href')).toBe(pipeline.path);
      });

      it('includes pipeline icon', () => {
        expect(findPipelineIcon().exists()).toBe(true);
        expect(findPipelineIcon().props('name')).toBe('pipeline');
      });

      it('includes pipeline label', () => {
        expect(findGlLink().text()).toBe(pipeline.label);
      });
    });
  });

  describe('without job data', () => {
    beforeEach(() => {
      wrapper = createWrapper({ job: null });
    });

    it('renders an API badge', () => {
      const badge = findBadge();

      expect(badge.exists()).toBe(true);
      expect(badge.props('variant')).toBe('info');
      expect(badge.text()).toBe('API');
    });
  });
});
