import Vue from 'vue';
import router from '~/ide/ide_router';
import Item from '~/ide/components/merge_requests/item.vue';
import mountCompontent from '../../../helpers/vue_mount_component_helper';

describe('IDE merge request item', () => {
  const Component = Vue.extend(Item);
  let vm;

  beforeEach(() => {
    vm = mountCompontent(Component, {
      item: {
        iid: 1,
        projectPathWithNamespace: 'gitlab-org/gitlab-ce',
        title: 'Merge request title',
      },
      currentId: '1',
      currentProjectId: 'gitlab-org/gitlab-ce',
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders merge requests data', () => {
    expect(vm.$el.textContent).toContain('Merge request title');
    expect(vm.$el.textContent).toContain('gitlab-org/gitlab-ce!1');
  });

  it('renders link with href', () => {
    const expectedHref = router.resolve(
      `/project/${vm.item.projectPathWithNamespace}/merge_requests/${vm.item.iid}`,
    ).href;

    expect(vm.$el.tagName.toLowerCase()).toBe('a');
    expect(vm.$el).toHaveAttr('href', expectedHref);
  });

  it('renders icon if ID matches currentId', () => {
    expect(vm.$el.querySelector('.ic-mobile-issue-close')).not.toBe(null);
  });

  it('does not render icon if ID does not match currentId', done => {
    vm.currentId = '2';

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.ic-mobile-issue-close')).toBe(null);

      done();
    });
  });

  it('does not render icon if project ID does not match', done => {
    vm.currentProjectId = 'test/test';

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.ic-mobile-issue-close')).toBe(null);

      done();
    });
  });
});
