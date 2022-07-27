import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import closedComponent from '~/vue_merge_request_widget/components/states/mr_widget_closed.vue';

describe('MRWidgetClosed', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(closedComponent);
    vm = mountComponent(Component, {
      mr: {
        metrics: {
          mergedBy: {},
          closedBy: {
            name: 'Administrator',
            username: 'root',
            webUrl: 'http://localhost:3000/root',
            avatarUrl:
              'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          },
          mergedAt: 'Jan 24, 2018 1:02pm UTC',
          closedAt: 'Jan 24, 2018 1:02pm UTC',
          readableMergedAt: '',
          readableClosedAt: 'less than a minute ago',
        },
        targetBranchPath: '/twitter/flight/commits/so_long_jquery',
        targetBranch: 'so_long_jquery',
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders warning icon', () => {
    expect(vm.$el.querySelector('.js-ci-status-icon-warning')).not.toBeNull();
  });
});
