import { shallowMount } from '@vue/test-utils';
import ReportLink from '~/ci/reports/components/report_link.vue';

describe('app/assets/javascripts/ci/reports/components/report_link.vue', () => {
  let wrapper;

  const defaultProps = {
    issue: {},
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ReportLink, {
      propsData: { ...defaultProps, ...props },
    });
  };

  describe('When an issue prop has a $urlPath property', () => {
    it('render a link that will take the user to the $urlPath', () => {
      createComponent({ issue: { path: 'Gemfile.lock', urlPath: '/Gemfile.lock' } });

      expect(wrapper.text()).toContain('in');
      expect(wrapper.find('a').attributes('href')).toBe('/Gemfile.lock');
      expect(wrapper.find('a').text()).toContain('Gemfile.lock');
    });
  });

  describe('When an issue prop has no $urlPath property', () => {
    it('does not render link', () => {
      createComponent({ issue: { path: 'Gemfile.lock' } });

      expect(wrapper.find('a').exists()).toBe(false);
      expect(wrapper.text()).toContain('in');
      expect(wrapper.text()).toContain('Gemfile.lock');
    });
  });

  describe('When an issue prop has a $line property', () => {
    it('render a line number', () => {
      createComponent({ issue: { path: 'Gemfile.lock', urlPath: '/Gemfile.lock', line: 22 } });

      expect(wrapper.find('a').text()).toContain('Gemfile.lock:22');
    });
  });

  describe('When an issue prop does not have a $line property', () => {
    it('does not render a line number', () => {
      createComponent({ issue: { urlPath: '/Gemfile.lock' } });

      expect(wrapper.find('a').text()).not.toContain(':22');
    });
  });
});
