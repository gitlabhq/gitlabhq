import Vue from 'vue';
import component from '~/jobs/components/unmet_prerequisites_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Unmet Prerequisites Block Job component', () => {
  const Component = Vue.extend(component);
  let vm;
  const helpPath = '/user/project/clusters/index.html#troubleshooting-failed-deployment-jobs';

  beforeEach(() => {
    vm = mountComponent(Component, {
      hasNoRunnersForProject: true,
      helpPath,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders an alert with the correct message', () => {
    const container = vm.$el.querySelector('.js-failed-unmet-prerequisites');
    const alertMessage =
      'This job failed because the necessary resources were not successfully created.';

    expect(container).not.toBeNull();
    expect(container.innerHTML).toContain(alertMessage);
  });

  it('renders link to help page', () => {
    const helpLink = vm.$el.querySelector('.js-help-path');

    expect(helpLink).not.toBeNull();
    expect(helpLink.innerHTML).toContain('More information');
    expect(helpLink.getAttribute('href')).toEqual(helpPath);
  });
});
