import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import component from 'ee/vue_shared/security_reports/split_security_reports_app.vue';
import createStore from 'ee/vue_shared/security_reports/store';
import state from 'ee/vue_shared/security_reports/store/state';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { sastIssues, dast, dockerReport } from './mock_data';

describe('Split security reports app', () => {
  const Component = Vue.extend(component);

  let vm;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    vm.$store.replaceState(state());
    vm.$destroy();
    mock.restore();
  });

  describe('while loading', () => {
    beforeEach(() => {
      mock.onGet('sast_head.json').reply(200, sastIssues);
      mock.onGet('dss_head.json').reply(200, sastIssues);
      mock.onGet('dast_head.json').reply(200, dast);
      mock.onGet('sast_container_head.json').reply(200, dockerReport);
      mock.onGet('vulnerability_feedback_path.json').reply(200, []);

      vm = mountComponentWithStore(Component, {
        store: createStore(),
        props: {
          headBlobPath: 'path',
          baseBlobPath: 'path',
          sastHeadPath: 'sast_head.json',
          dependencyScanningHeadPath: 'dss_head.json',
          dastHeadPath: 'dast_head.json',
          sastContainerHeadPath: 'sast_container_head.json',
          sastHelpPath: 'path',
          dependencyScanningHelpPath: 'path',
          vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
          vulnerabilityFeedbackHelpPath: 'path',
          dastHelpPath: 'path',
          sastContainerHelpPath: 'path',
          pipelineId: 123,
          canCreateIssue: true,
          canCreateFeedback: true,
        },
      });
    });

    it('renders loading summary text + spinner', done => {
      expect(vm.$el.querySelector('.fa-spinner')).not.toBeNull();

      expect(vm.$el.textContent).toContain('SAST is loading');
      expect(vm.$el.textContent).toContain('Dependency scanning is loading');
      expect(vm.$el.textContent).toContain('Container scanning is loading');
      expect(vm.$el.textContent).toContain('DAST is loading');

      setTimeout(() => {
        done();
      }, 0);
    });
  });

  describe('with all reports', () => {
    beforeEach(() => {
      mock.onGet('sast_head.json').reply(200, sastIssues);
      mock.onGet('dss_head.json').reply(200, sastIssues);
      mock.onGet('dast_head.json').reply(200, dast);
      mock.onGet('sast_container_head.json').reply(200, dockerReport);
      mock.onGet('vulnerability_feedback_path.json').reply(200, []);

      vm = mountComponentWithStore(Component, {
        store: createStore(),
        props: {
          headBlobPath: 'path',
          baseBlobPath: 'path',
          sastHeadPath: 'sast_head.json',
          dependencyScanningHeadPath: 'dss_head.json',
          dastHeadPath: 'dast_head.json',
          sastContainerHeadPath: 'sast_container_head.json',
          sastHelpPath: 'path',
          dependencyScanningHelpPath: 'path',
          vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
          vulnerabilityFeedbackHelpPath: 'path',
          dastHelpPath: 'path',
          sastContainerHelpPath: 'path',
          pipelineId: 123,
          canCreateIssue: true,
          canCreateFeedback: true,
        },
      });
    });

    it('renders reports', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.fa-spinner')).toBeNull();

        expect(vm.$el.textContent).toContain('SAST detected 3 vulnerabilities');
        expect(vm.$el.textContent).toContain('Dependency scanning detected 3 vulnerabilities');

        // Renders container scanning result
        expect(vm.$el.textContent).toContain('Container scanning detected 2 vulnerabilities');

        // Renders DAST result
        expect(vm.$el.textContent).toContain('DAST detected 2 vulnerabilities');

        done();
      }, 0);
    });

    it('renders all reports collapsed by default', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.fa-spinner')).toBeNull();
        expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

        const reports = vm.$el.querySelectorAll('.js-report-section-container');

        reports.forEach(report => {
          expect(report).toHaveCss({ display: 'none' });
        });

        done();
      }, 0);
    });

    it('renders all reports expanded with the option always-open', done => {
      vm.alwaysOpen = true;

      setTimeout(() => {
        expect(vm.$el.querySelector('.fa-spinner')).toBeNull();
        expect(vm.$el.querySelector('.js-collapse-btn')).toBeNull();

        const reports = vm.$el.querySelectorAll('.js-report-section-container');

        reports.forEach(report => {
          expect(report).not.toHaveCss({ display: 'none' });
        });

        done();
      }, 0);
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      mock.onGet('sast_head.json').reply(500);
      mock.onGet('dss_head.json').reply(500);
      mock.onGet('dast_head.json').reply(500);
      mock.onGet('sast_container_head.json').reply(500);
      mock.onGet('vulnerability_feedback_path.json').reply(500, []);

      vm = mountComponentWithStore(Component, {
        store: createStore(),
        props: {
          headBlobPath: 'path',
          baseBlobPath: 'path',
          sastHeadPath: 'sast_head.json',
          dependencyScanningHeadPath: 'dss_head.json',
          dastHeadPath: 'dast_head.json',
          sastContainerHeadPath: 'sast_container_head.json',
          sastHelpPath: 'path',
          dependencyScanningHelpPath: 'path',
          vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
          vulnerabilityFeedbackHelpPath: 'path',
          dastHelpPath: 'path',
          sastContainerHelpPath: 'path',
          pipelineId: 123,
          canCreateIssue: true,
          canCreateFeedback: true,
        },
      });
    });

    it('renders error state', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.fa-spinner')).toBeNull();

        expect(vm.$el.textContent).toContain('SAST resulted in error while loading results');
        expect(vm.$el.textContent).toContain(
          'Dependency scanning resulted in error while loading results',
        );
        expect(vm.$el.textContent).toContain(
          'Container scanning resulted in error while loading results',
        );
        expect(vm.$el.textContent).toContain('DAST resulted in error while loading results');
        done();
      }, 0);
    });
  });
});
