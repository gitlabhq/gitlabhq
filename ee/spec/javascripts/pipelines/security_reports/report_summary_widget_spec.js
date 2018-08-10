import Vue from 'vue';
import store from 'ee/vue_shared/security_reports/store';
import state from 'ee/vue_shared/security_reports/store/state';
import reportSummary from 'ee/pipelines/components/security_reports/report_summary_widget.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { sastIssues, dast, dockerReport } from 'ee_spec/vue_shared/security_reports/mock_data';

describe('Report summary widget', () => {
  const Component = Vue.extend(reportSummary);
  let vm;

  beforeEach(() => {
    vm = createComponentWithStore(Component, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();
    // clean up the error state
    vm.$store.replaceState(state());
  });

  describe('without paths', () => {
    it('does not render any summary', () => {
      expect(vm.$el.querySelector('.js-sast-summary')).toBeNull();
      expect(vm.$el.querySelector('.js-dss-summary')).toBeNull();
    });
  });

  describe('while loading', () => {
    beforeEach(() => {
      vm.$store.dispatch('setSastHeadPath', 'head.json');
      vm.$store.dispatch('setDependencyScanningHeadPath', 'head.json');
      vm.$store.dispatch('setDastHeadPath', 'head.json');
      vm.$store.dispatch('setSastContainerHeadPath', 'head.json');

      vm.$store.dispatch('requestSastReports');
      vm.$store.dispatch('requestDependencyScanningReports');
      vm.$store.dispatch('requestDastReports');
      vm.$store.dispatch('requestSastContainerReports');
    });

    it('renders loading icon and text for sast', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-sast-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('SAST is loading');

        expect(vm.$el.querySelector('.js-sast-summary .fa-spinner')).not.toBeNull();
        done();
      });
    });

    it('renders loading icon and text for dependency scanning', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-dss-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('Dependency scanning is loading');

        expect(vm.$el.querySelector('.js-dss-summary .fa-spinner')).not.toBeNull();
        done();
      });
    });

    it('renders loading icon and text for container scanning', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-sast-container-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('Container scanning is loading');

        expect(vm.$el.querySelector('.js-sast-container-summary .fa-spinner')).not.toBeNull();
        done();
      });
    });

    it('renders loading icon and text for dast', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-dast-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('DAST is loading');

        expect(vm.$el.querySelector('.js-dast-summary .fa-spinner')).not.toBeNull();
        done();
      });
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      vm.$store.dispatch('setSastHeadPath', 'head.json');
      vm.$store.dispatch('setDependencyScanningHeadPath', 'head.json');
      vm.$store.dispatch('setDastHeadPath', 'head.json');
      vm.$store.dispatch('setSastContainerHeadPath', 'head.json');

      vm.$store.dispatch('receiveSastError');
      vm.$store.dispatch('receiveDependencyScanningError');
      vm.$store.dispatch('receiveSastContainerError');
      vm.$store.dispatch('receiveDastError');
    });

    it('renders warning icon and error text for sast', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-sast-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('SAST resulted in error while loading results');

        expect(vm.$el.querySelector('.js-sast-summary .js-ci-status-icon-warning')).not.toBeNull();
        done();
      });
    });

    it('renders warnin icon and error text for dependency scanning', done => {
      vm.$nextTick()
        .then(() => {
          expect(
            vm.$el
              .querySelector('.js-dss-summary')
              .textContent.trim()
              .replace(/\s\s+/g, ' '),
          ).toEqual('Dependency scanning resulted in error while loading results');

          expect(vm.$el.querySelector('.js-dss-summary .js-ci-status-icon-warning')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders warnin icon and error text for container scanning', done => {
      vm.$nextTick()
        .then(() => {
          expect(
            vm.$el
              .querySelector('.js-sast-container-summary')
              .textContent.trim()
              .replace(/\s\s+/g, ' '),
          ).toEqual('Container scanning resulted in error while loading results');

          expect(vm.$el.querySelector('.js-sast-container-summary .js-ci-status-icon-warning')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders warnin icon and error text for DAST', done => {
      vm.$nextTick()
        .then(() => {
          expect(
            vm.$el
              .querySelector('.js-dast-summary')
              .textContent.trim()
              .replace(/\s\s+/g, ' '),
          ).toEqual('DAST resulted in error while loading results');

          expect(vm.$el.querySelector('.js-dast-summary .js-ci-status-icon-warning')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('with vulnerabilities', () => {
    beforeEach(() => {
      vm.$store.dispatch('setSastHeadPath', 'head.json');
      vm.$store.dispatch('setDependencyScanningHeadPath', 'head.json');
      vm.$store.dispatch('setDastHeadPath', 'head.json');
      vm.$store.dispatch('setSastContainerHeadPath', 'head.json');

      vm.$store.dispatch('receiveSastReports', {
        head: sastIssues,
      });
      vm.$store.dispatch('receiveDependencyScanningReports', {
        head: sastIssues,
      });
      vm.$store.dispatch('receiveSastContainerReports', {
        head: dockerReport,
      });
      vm.$store.dispatch('receiveDastReports', {
        head: dast,
      });
    });

    it('renders warning icon and vulnerabilities text for sast', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-sast-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('SAST detected 3 vulnerabilities');

        expect(vm.$el.querySelector('.js-sast-summary .js-ci-status-icon-warning')).not.toBeNull();
        done();
      });
    });

    it('renders warning icon and vulnerabilities text for dependency scanning', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-dss-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('Dependency scanning detected 3 vulnerabilities');

        expect(vm.$el.querySelector('.js-dss-summary .js-ci-status-icon-warning')).not.toBeNull();
        done();
      });
    });

    it('renders warning icon and vulnerabilities text for container scanning', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-sast-container-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('Container scanning detected 2 vulnerabilities');

        expect(vm.$el.querySelector('.js-sast-container-summary .js-ci-status-icon-warning')).not.toBeNull();
        done();
      });
    });

    it('renders warning icon and vulnerabilities text for dast', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-dast-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('DAST detected 2 vulnerabilities');

        expect(vm.$el.querySelector('.js-dast-summary .js-ci-status-icon-warning')).not.toBeNull();
        done();
      });
    });
  });

  describe('without vulnerabilities', () => {
    beforeEach(() => {
      vm.$store.dispatch('setSastHeadPath', 'head.json');
      vm.$store.dispatch('setDependencyScanningHeadPath', 'head.json');
      vm.$store.dispatch('setDastHeadPath', 'head.json');
      vm.$store.dispatch('setSastContainerHeadPath', 'head.json');

      vm.$store.dispatch('receiveSastReports', {
        head: [],
      });
      vm.$store.dispatch('receiveDependencyScanningReports', {
        head: [],
      });
      vm.$store.dispatch('receiveSastContainerReports', {
        head: [],
      });
      vm.$store.dispatch('receiveDastReports', {
        head: [],
      });
    });

    it('renders success icon and vulnerabilities text for sast', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-sast-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('SAST detected no vulnerabilities');

        expect(vm.$el.querySelector('.js-sast-summary .js-ci-status-icon-success')).not.toBeNull();
        done();
      });
    });

    it('renders success icon and vulnerabilities text for dependency scanning', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-dss-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('Dependency scanning detected no vulnerabilities');

        expect(vm.$el.querySelector('.js-dss-summary .js-ci-status-icon-success')).not.toBeNull();
        done();
      });
    });

    it('renders success icon and vulnerabilities text for container scanning', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-sast-container-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('Container scanning detected no vulnerabilities');

        expect(vm.$el.querySelector('.js-sast-container-summary .js-ci-status-icon-success')).not.toBeNull();
        done();
      });
    });

    it('renders success icon and vulnerabilities text for dast', done => {
      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-dast-summary')
            .textContent.trim()
            .replace(/\s\s+/g, ' '),
        ).toEqual('DAST detected no vulnerabilities');

        expect(vm.$el.querySelector('.js-dast-summary .js-ci-status-icon-success')).not.toBeNull();
        done();
      });
    });
  });
});
