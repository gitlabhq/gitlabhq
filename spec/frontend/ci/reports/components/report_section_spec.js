import { GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import ReportItem from '~/ci/reports/components/report_item.vue';
import ReportSection from '~/ci/reports/components/report_section.vue';

describe('ReportSection component', () => {
  let wrapper;

  const findExpandButton = () => wrapper.findComponent(GlButton);
  const findPopover = () => wrapper.findComponent(HelpPopover);
  const findReportSection = () => wrapper.find('.js-report-section-container');
  const expectExpandButtonOpen = () =>
    expect(findExpandButton().props('icon')).toBe('chevron-lg-up');
  const expectExpandButtonClosed = () =>
    expect(findExpandButton().props('icon')).toBe('chevron-lg-down');

  const resolvedIssues = [
    {
      name: 'Insecure Dependency',
      fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
      path: 'Gemfile.lock',
      line: 12,
      urlPath: 'foo/Gemfile.lock',
    },
  ];

  const defaultProps = {
    component: '',
    status: 'SUCCESS',
    loadingText: 'Loading Code Quality report',
    errorText: 'foo',
    successText: 'Code quality improved on 1 point and degraded on 1 point',
    resolvedIssues,
    hasIssues: false,
    alwaysOpen: false,
  };

  const createComponent = ({ props = {}, data = {}, slots = {} } = {}) => {
    wrapper = mountExtended(ReportSection, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      data() {
        return data;
      },
      slots,
    });
  };

  describe('computed', () => {
    describe('isCollapsible', () => {
      const testMatrix = [
        { hasIssues: false, alwaysOpen: false, isCollapsible: false },
        { hasIssues: false, alwaysOpen: true, isCollapsible: false },
        { hasIssues: true, alwaysOpen: false, isCollapsible: true },
        { hasIssues: true, alwaysOpen: true, isCollapsible: false },
      ];

      testMatrix.forEach(({ hasIssues, alwaysOpen, isCollapsible }) => {
        const issues = hasIssues ? 'has issues' : 'has no issues';
        const open = alwaysOpen ? 'is always open' : 'is not always open';

        it(`is ${isCollapsible}, if the report ${issues} and ${open}`, () => {
          createComponent({ props: { hasIssues, alwaysOpen } });

          expect(wrapper.vm.isCollapsible).toBe(isCollapsible);
        });
      });
    });

    describe('isExpanded', () => {
      const testMatrix = [
        { isCollapsed: false, alwaysOpen: false, isExpanded: true },
        { isCollapsed: false, alwaysOpen: true, isExpanded: true },
        { isCollapsed: true, alwaysOpen: false, isExpanded: false },
        { isCollapsed: true, alwaysOpen: true, isExpanded: true },
      ];

      testMatrix.forEach(({ isCollapsed, alwaysOpen, isExpanded }) => {
        const issues = isCollapsed ? 'is collapsed' : 'is not collapsed';
        const open = alwaysOpen ? 'is always open' : 'is not always open';

        it(`is ${isExpanded}, if the report ${issues} and ${open}`, () => {
          createComponent({ props: { alwaysOpen }, data: { isCollapsed } });

          expect(wrapper.vm.isExpanded).toBe(isExpanded);
        });
      });
    });
  });

  describe('when it is loading', () => {
    it('should render loading indicator', () => {
      createComponent({
        props: {
          component: '',
          status: 'LOADING',
          loadingText: 'Loading Code Quality report',
          errorText: 'foo',
          successText: 'Code quality improved on 1 point and degraded on 1 point',
          hasIssues: false,
        },
      });

      expect(wrapper.text()).toBe('Loading Code Quality report');
    });
  });

  describe('with success status', () => {
    it('should render provided data', () => {
      createComponent({ props: { hasIssues: true } });

      expect(wrapper.find('.js-code-text').text()).toBe(
        'Code quality improved on 1 point and degraded on 1 point',
      );
      expect(wrapper.findAllComponents(ReportItem)).toHaveLength(resolvedIssues.length);
    });

    describe('toggleCollapsed', () => {
      it('toggles issues', async () => {
        createComponent({ props: { hasIssues: true } });

        await findExpandButton().trigger('click');

        expect(findReportSection().isVisible()).toBe(true);
        expectExpandButtonOpen();

        await findExpandButton().trigger('click');

        expect(findReportSection().isVisible()).toBe(false);
        expectExpandButtonClosed();
      });

      it('is always expanded, if always-open is set to true', () => {
        createComponent({ props: { hasIssues: true, alwaysOpen: true } });

        expect(findReportSection().isVisible()).toBe(true);
        expect(findExpandButton().exists()).toBe(false);
      });
    });
  });

  describe('snowplow events', () => {
    it('does emit an event on issue toggle if the shouldEmitToggleEvent prop does exist', () => {
      createComponent({ props: { hasIssues: true, shouldEmitToggleEvent: true } });

      expect(wrapper.emitted('toggleEvent')).toBeUndefined();

      findExpandButton().trigger('click');

      expect(wrapper.emitted('toggleEvent')).toEqual([[]]);
    });

    it('does not emit an event on issue toggle if the shouldEmitToggleEvent prop does not exist', () => {
      createComponent({ props: { hasIssues: true } });

      expect(wrapper.emitted('toggleEvent')).toBeUndefined();

      findExpandButton().trigger('click');

      expect(wrapper.emitted('toggleEvent')).toBeUndefined();
    });

    it('does not emit an event if always-open is set to true', () => {
      createComponent({
        props: { alwaysOpen: true, hasIssues: true, shouldEmitToggleEvent: true },
      });

      expect(wrapper.emitted('toggleEvent')).toBeUndefined();
    });
  });

  describe('with failed request', () => {
    it('should render error indicator', () => {
      createComponent({
        props: {
          component: '',
          status: 'ERROR',
          loadingText: 'Loading Code Quality report',
          errorText: 'Failed to load Code Quality report',
          successText: 'Code quality improved on 1 point and degraded on 1 point',
          hasIssues: false,
        },
      });

      expect(wrapper.text()).toBe('Failed to load Code Quality report');
    });
  });

  describe('with action buttons passed to the slot', () => {
    beforeEach(() => {
      createComponent({
        props: {
          status: 'SUCCESS',
          successText: 'success',
          hasIssues: true,
        },
        slots: {
          'action-buttons': ['Action!'],
        },
      });
    });

    it('should render the passed button', () => {
      expect(wrapper.text()).toContain('Action!');
    });

    it('should still render the expand/collapse button', () => {
      expectExpandButtonClosed();
    });
  });

  describe('Success and Error slots', () => {
    const createComponentWithSlots = (status) => {
      createComponent({
        props: {
          status,
          hasIssues: true,
        },
        slots: {
          success: ['This is a success'],
          loading: ['This is loading'],
          error: ['This is an error'],
        },
      });
    };

    it('only renders success slot when status is "SUCCESS"', () => {
      createComponentWithSlots('SUCCESS');

      expect(wrapper.text()).toContain('This is a success');
      expect(wrapper.text()).not.toContain('This is an error');
      expect(wrapper.text()).not.toContain('This is loading');
    });

    it('only renders error slot when status is "ERROR"', () => {
      createComponentWithSlots('ERROR');

      expect(wrapper.text()).toContain('This is an error');
      expect(wrapper.text()).not.toContain('This is a success');
      expect(wrapper.text()).not.toContain('This is loading');
    });

    it('only renders loading slot when status is "LOADING"', () => {
      createComponentWithSlots('LOADING');

      expect(wrapper.text()).toContain('This is loading');
      expect(wrapper.text()).not.toContain('This is an error');
      expect(wrapper.text()).not.toContain('This is a success');
    });
  });

  describe('help popover', () => {
    describe('when popover options are defined', () => {
      const options = {
        title: 'foo',
        content: 'bar',
      };

      beforeEach(() => {
        createComponent({ props: { popoverOptions: options } });
      });

      it('popover is shown with options', () => {
        expect(findPopover().props('options')).toEqual(options);
      });
    });

    describe('when popover options are not defined', () => {
      beforeEach(() => {
        createComponent({ props: { popoverOptions: {} } });
      });

      it('popover is not shown', () => {
        expect(findPopover().exists()).toBe(false);
      });
    });
  });
});
