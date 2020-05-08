import Vue from 'vue';
import sidebarDetailsBlock from '~/jobs/components/sidebar.vue';
import createStore from '~/jobs/store';
import job, { jobsInStage } from '../mock_data';
import { mountComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { trimText } from '../../helpers/text_helper';

describe('Sidebar details block', () => {
  const SidebarComponent = Vue.extend(sidebarDetailsBlock);
  let vm;
  let store;

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('when there is no retry path retry', () => {
    it('should not render a retry button', () => {
      const copy = { ...job };
      delete copy.retry_path;

      store.dispatch('receiveJobSuccess', copy);
      vm = mountComponentWithStore(SidebarComponent, {
        store,
      });

      expect(vm.$el.querySelector('.js-retry-button')).toBeNull();
    });
  });

  describe('without terminal path', () => {
    it('does not render terminal link', () => {
      store.dispatch('receiveJobSuccess', job);
      vm = mountComponentWithStore(SidebarComponent, { store });

      expect(vm.$el.querySelector('.js-terminal-link')).toBeNull();
    });
  });

  describe('with terminal path', () => {
    it('renders terminal link', () => {
      store.dispatch('receiveJobSuccess', { ...job, terminal_path: 'job/43123/terminal' });
      vm = mountComponentWithStore(SidebarComponent, {
        store,
      });

      expect(vm.$el.querySelector('.js-terminal-link')).not.toBeNull();
    });
  });

  beforeEach(() => {
    store.dispatch('receiveJobSuccess', job);
    vm = mountComponentWithStore(SidebarComponent, { store });
  });

  describe('actions', () => {
    it('should render link to new issue', () => {
      expect(vm.$el.querySelector('.js-new-issue').getAttribute('href')).toEqual(
        job.new_issue_path,
      );

      expect(vm.$el.querySelector('.js-new-issue').textContent.trim()).toEqual('New issue');
    });

    it('should render link to retry job', () => {
      expect(vm.$el.querySelector('.js-retry-button').getAttribute('href')).toEqual(job.retry_path);
    });

    it('should render link to cancel job', () => {
      expect(vm.$el.querySelector('.js-cancel-job').getAttribute('href')).toEqual(job.cancel_path);
    });
  });

  describe('information', () => {
    it('should render job duration', () => {
      expect(trimText(vm.$el.querySelector('.js-job-duration').textContent)).toEqual(
        'Duration: 6 seconds',
      );
    });

    it('should render erased date', () => {
      expect(trimText(vm.$el.querySelector('.js-job-erased').textContent)).toEqual(
        'Erased: 3 weeks ago',
      );
    });

    it('should render finished date', () => {
      expect(trimText(vm.$el.querySelector('.js-job-finished').textContent)).toEqual(
        'Finished: 3 weeks ago',
      );
    });

    it('should render queued date', () => {
      expect(trimText(vm.$el.querySelector('.js-job-queued').textContent)).toEqual(
        'Queued: 9 seconds',
      );
    });

    it('should render runner ID', () => {
      expect(trimText(vm.$el.querySelector('.js-job-runner').textContent)).toEqual(
        'Runner: local ci runner (#1)',
      );
    });

    it('should render timeout information', () => {
      expect(trimText(vm.$el.querySelector('.js-job-timeout').textContent)).toEqual(
        'Timeout: 1m 40s (from runner)',
      );
    });

    it('should render coverage', () => {
      expect(trimText(vm.$el.querySelector('.js-job-coverage').textContent)).toEqual(
        'Coverage: 20%',
      );
    });

    it('should render tags', () => {
      expect(trimText(vm.$el.querySelector('.js-job-tags').textContent)).toEqual('Tags: tag');
    });
  });

  describe('stages dropdown', () => {
    beforeEach(() => {
      store.dispatch('receiveJobSuccess', job);
    });

    describe('with stages', () => {
      beforeEach(() => {
        vm = mountComponentWithStore(SidebarComponent, { store });
      });

      it('renders value provided as selectedStage as selected', () => {
        expect(vm.$el.querySelector('.js-selected-stage').textContent.trim()).toEqual(
          vm.selectedStage,
        );
      });
    });

    describe('without jobs for stages', () => {
      beforeEach(() => {
        store.dispatch('receiveJobSuccess', job);
        vm = mountComponentWithStore(SidebarComponent, { store });
      });

      it('does not render job container', () => {
        expect(vm.$el.querySelector('.js-jobs-container')).toBeNull();
      });
    });

    describe('with jobs for stages', () => {
      beforeEach(() => {
        store.dispatch('receiveJobSuccess', job);
        store.dispatch('receiveJobsForStageSuccess', jobsInStage.latest_statuses);
        vm = mountComponentWithStore(SidebarComponent, { store });
      });

      it('renders list of jobs', () => {
        expect(vm.$el.querySelector('.js-jobs-container')).not.toBeNull();
      });
    });
  });
});
