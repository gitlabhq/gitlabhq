import { GlBadge, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import JobSourceBadge from '~/ci/job_details/components/job_source_badge.vue';

describe('JobSourceBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findIcon = () => wrapper.findComponent(GlIcon);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(JobSourceBadge, {
      propsData: props,
    });
  };

  describe('when source is null', () => {
    beforeEach(() => {
      createComponent({ source: null });
    });

    it('does not render a badge', () => {
      expect(findBadge().exists()).toBe(false);
    });
  });

  describe('when source is not a recognized type', () => {
    beforeEach(() => {
      createComponent({ source: 'push' });
    });

    it('does not render a badge', () => {
      expect(findBadge().exists()).toBe(false);
    });
  });

  describe.each([
    {
      source: 'scan_execution_policy',
      variant: 'info',
      label: 'Security policy',
      tooltip: 'This job was added by a scan execution policy',
    },
    {
      source: 'pipeline_execution_policy',
      variant: 'info',
      label: 'Security policy',
      tooltip: 'This job was added by a pipeline execution policy',
    },
  ])('when source is $source', ({ source, variant, label, tooltip }) => {
    beforeEach(() => {
      createComponent({ source });
    });

    it('renders a badge', () => {
      expect(findBadge().exists()).toBe(true);
    });

    it(`renders with ${variant} variant`, () => {
      expect(findBadge().props('variant')).toBe(variant);
    });

    it('renders the correct label', () => {
      expect(findBadge().text()).toContain(label);
    });

    it('has the correct tooltip', () => {
      expect(findBadge().attributes('title')).toBe(tooltip);
    });
  });

  describe('compact mode', () => {
    beforeEach(() => {
      createComponent({ source: 'scan_execution_policy', compact: true });
    });

    it('renders icon-only badge', () => {
      expect(findBadge().props('icon')).toBe('shield');
    });

    it('does not render label text', () => {
      expect(findBadge().text()).toBe('');
    });

    it('has the correct tooltip', () => {
      expect(findBadge().attributes('title')).toBe('This job was added by a scan execution policy');
    });
  });

  describe('non-compact mode (default)', () => {
    beforeEach(() => {
      createComponent({ source: 'scan_execution_policy' });
    });

    it('does not pass icon prop to badge', () => {
      expect(findBadge().props('icon')).toBeNull();
    });

    it('renders inline shield icon with label text', () => {
      expect(findIcon().props('name')).toBe('shield');
      expect(findBadge().text()).toContain('Security policy');
    });
  });
});
