import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SecuritySummary from '~/vue_shared/security_reports/components/security_summary.vue';
import { groupedTextBuilder } from '~/vue_shared/security_reports/store/utils';

describe('Severity Summary', () => {
  let wrapper;

  const createWrapper = message => {
    wrapper = shallowMount(SecuritySummary, {
      propsData: { message },
      stubs: {
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each([
    { message: '' },
    { message: 'foo' },
    groupedTextBuilder({ reportType: 'Security scanning', critical: 1, high: 0, total: 1 }),
    groupedTextBuilder({ reportType: 'Security scanning', critical: 0, high: 1, total: 1 }),
    groupedTextBuilder({ reportType: 'Security scanning', critical: 1, high: 2, total: 3 }),
  ])('given the message %p', message => {
    beforeEach(() => {
      createWrapper(message);
    });

    it('interpolates correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
