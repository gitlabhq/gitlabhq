import Vue from 'vue';
import reportSection from '~/vue_shared/components/reports/report_section.vue';
import { componentNames } from 'ee/vue_shared/components/reports/issue_body';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { fullReport } from './report_section_mock_data';

describe('Report section', () => {
  let vm;
  const ReportSection = Vue.extend(reportSection);

  afterEach(() => {
    vm.$destroy();
  });

  describe('With full report', () => {
    beforeEach(() => {
      vm = mountComponent(ReportSection, {
        component: componentNames.SastIssueBody,
        ...fullReport,
      });
    });

    it('should render full report section', done => {
      vm.$el.querySelector('button').click();

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.js-expand-full-list').textContent.trim()).toEqual(
          'Show complete code vulnerabilities report',
        );

        done();
      });
    });

    it('should expand full list when clicked and hide the show all button', done => {
      vm.$el.querySelector('button').click();

      Vue.nextTick(() => {
        vm.$el.querySelector('.js-expand-full-list').click();

        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.js-mr-code-all-issues').textContent.trim()).toContain(
            'Possible Information Leak Vulnerability in Action View',
          );

          done();
        });
      });
    });
  });
});
