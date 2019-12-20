import Vue from 'vue';
import mountComponent, { mountComponentWithSlots } from 'helpers/vue_mount_component_helper';
import reportSection from '~/reports/components/report_section.vue';

describe('Report section', () => {
  let vm;
  const ReportSection = Vue.extend(reportSection);

  const resolvedIssues = [
    {
      name: 'Insecure Dependency',
      fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
      path: 'Gemfile.lock',
      line: 12,
      urlPath: 'foo/Gemfile.lock',
    },
  ];

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    beforeEach(() => {
      vm = mountComponent(ReportSection, {
        component: '',
        status: 'SUCCESS',
        loadingText: 'Loading codeclimate report',
        errorText: 'foo',
        successText: 'Code quality improved on 1 point and degraded on 1 point',
        resolvedIssues,
        hasIssues: false,
        alwaysOpen: false,
      });
    });

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

        it(`is ${isCollapsible}, if the report ${issues} and ${open}`, done => {
          vm.hasIssues = hasIssues;
          vm.alwaysOpen = alwaysOpen;

          Vue.nextTick()
            .then(() => {
              expect(vm.isCollapsible).toBe(isCollapsible);
            })
            .then(done)
            .catch(done.fail);
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

        it(`is ${isExpanded}, if the report ${issues} and ${open}`, done => {
          vm.isCollapsed = isCollapsed;
          vm.alwaysOpen = alwaysOpen;

          Vue.nextTick()
            .then(() => {
              expect(vm.isExpanded).toBe(isExpanded);
            })
            .then(done)
            .catch(done.fail);
        });
      });
    });
  });

  describe('when it is loading', () => {
    it('should render loading indicator', () => {
      vm = mountComponent(ReportSection, {
        component: '',
        status: 'LOADING',
        loadingText: 'Loading codeclimate report',
        errorText: 'foo',
        successText: 'Code quality improved on 1 point and degraded on 1 point',
        hasIssues: false,
      });

      expect(vm.$el.textContent.trim()).toEqual('Loading codeclimate report');
    });
  });

  describe('with success status', () => {
    beforeEach(() => {
      vm = mountComponent(ReportSection, {
        component: '',
        status: 'SUCCESS',
        loadingText: 'Loading codeclimate report',
        errorText: 'foo',
        successText: 'Code quality improved on 1 point and degraded on 1 point',
        resolvedIssues,
        hasIssues: true,
      });
    });

    it('should render provided data', () => {
      expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Code quality improved on 1 point and degraded on 1 point',
      );

      expect(vm.$el.querySelectorAll('.report-block-container li').length).toEqual(
        resolvedIssues.length,
      );
    });

    describe('toggleCollapsed', () => {
      const hiddenCss = { display: 'none' };

      it('toggles issues', done => {
        vm.$el.querySelector('button').click();

        Vue.nextTick()
          .then(() => {
            expect(vm.$el.querySelector('.js-report-section-container')).not.toHaveCss(hiddenCss);
            expect(vm.$el.querySelector('button').textContent.trim()).toEqual('Collapse');

            vm.$el.querySelector('button').click();
          })
          .then(Vue.nextTick)
          .then(() => {
            expect(vm.$el.querySelector('.js-report-section-container')).toHaveCss(hiddenCss);
            expect(vm.$el.querySelector('button').textContent.trim()).toEqual('Expand');
          })
          .then(done)
          .catch(done.fail);
      });

      it('is always expanded, if always-open is set to true', done => {
        vm.alwaysOpen = true;
        Vue.nextTick()
          .then(() => {
            expect(vm.$el.querySelector('.js-report-section-container')).not.toHaveCss(hiddenCss);
            expect(vm.$el.querySelector('button')).toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('with failed request', () => {
    it('should render error indicator', () => {
      vm = mountComponent(ReportSection, {
        component: '',
        status: 'ERROR',
        loadingText: 'Loading codeclimate report',
        errorText: 'Failed to load codeclimate report',
        successText: 'Code quality improved on 1 point and degraded on 1 point',
        hasIssues: false,
      });

      expect(vm.$el.textContent.trim()).toEqual('Failed to load codeclimate report');
    });
  });

  describe('with action buttons passed to the slot', () => {
    beforeEach(() => {
      vm = mountComponentWithSlots(ReportSection, {
        props: {
          status: 'SUCCESS',
          successText: 'success',
          hasIssues: true,
        },
        slots: {
          actionButtons: ['Action!'],
        },
      });
    });

    it('should render the passed button', () => {
      expect(vm.$el.textContent.trim()).toContain('Action!');
    });

    it('should still render the expand/collapse button', () => {
      expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');
    });
  });

  describe('Success and Error slots', () => {
    const createComponent = status => {
      vm = mountComponentWithSlots(ReportSection, {
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
      createComponent('SUCCESS');

      expect(vm.$el.textContent.trim()).toContain('This is a success');
      expect(vm.$el.textContent.trim()).not.toContain('This is an error');
      expect(vm.$el.textContent.trim()).not.toContain('This is loading');
    });

    it('only renders error slot when status is "ERROR"', () => {
      createComponent('ERROR');

      expect(vm.$el.textContent.trim()).toContain('This is an error');
      expect(vm.$el.textContent.trim()).not.toContain('This is a success');
      expect(vm.$el.textContent.trim()).not.toContain('This is loading');
    });

    it('only renders loading slot when status is "LOADING"', () => {
      createComponent('LOADING');

      expect(vm.$el.textContent.trim()).toContain('This is loading');
      expect(vm.$el.textContent.trim()).not.toContain('This is an error');
      expect(vm.$el.textContent.trim()).not.toContain('This is a success');
    });
  });
});
