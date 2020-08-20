import Vue from 'vue';
import JobItem from '~/ide/components/jobs/item.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';
import { jobs } from '../../mock_data';

describe('IDE jobs item', () => {
  const Component = Vue.extend(JobItem);
  const job = jobs[0];
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      job,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders job details', () => {
    expect(vm.$el.textContent).toContain(job.name);
    expect(vm.$el.textContent).toContain(`#${job.id}`);
  });

  it('renders CI icon', () => {
    expect(vm.$el.querySelector('[data-testid="status_success_borderless-icon"]')).not.toBe(null);
  });

  it('does not render view logs button if not started', done => {
    vm.job.started = false;

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.btn')).toBe(null);

      done();
    });
  });
});
