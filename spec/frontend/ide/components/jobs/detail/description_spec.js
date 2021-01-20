import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import Description from '~/ide/components/jobs/detail/description.vue';
import { jobs } from '../../../mock_data';

describe('IDE job description', () => {
  const Component = Vue.extend(Description);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      job: jobs[0],
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders job details', () => {
    expect(vm.$el.textContent).toContain('#1');
    expect(vm.$el.textContent).toContain('test');
  });

  it('renders CI icon', () => {
    expect(
      vm.$el.querySelector('.ci-status-icon [data-testid="status_success_borderless-icon"]'),
    ).not.toBe(null);
  });

  it('renders bridge job details without the job link', () => {
    vm = mountComponent(Component, {
      job: { ...jobs[0], path: undefined },
    });

    expect(vm.$el.querySelector('[data-testid="description-detail-link"]')).toBe(null);
  });
});
