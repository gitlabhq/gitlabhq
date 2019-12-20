import Vue from 'vue';
import mountCompontent from 'helpers/vue_mount_component_helper';
import router from '~/ide/ide_router';
import Item from '~/ide/components/branches/item.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { projectData } from '../../mock_data';

const TEST_BRANCH = {
  name: 'master',
  committedDate: '2018-01-05T05:50Z',
};
const TEST_PROJECT_ID = projectData.name_with_namespace;

describe('IDE branch item', () => {
  const Component = Vue.extend(Item);
  let vm;

  beforeEach(() => {
    vm = mountCompontent(Component, {
      item: { ...TEST_BRANCH },
      projectId: TEST_PROJECT_ID,
      isActive: false,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders branch name and timeago', () => {
    const timeText = getTimeago().format(TEST_BRANCH.committedDate);

    expect(vm.$el.textContent).toContain(TEST_BRANCH.name);
    expect(vm.$el.querySelector('time')).toHaveText(timeText);
    expect(vm.$el.querySelector('.ic-mobile-issue-close')).toBe(null);
  });

  it('renders link to branch', () => {
    const expectedHref = router.resolve(`/project/${TEST_PROJECT_ID}/edit/${TEST_BRANCH.name}`)
      .href;

    expect(vm.$el.textContent).toMatch('a');
    expect(vm.$el).toHaveAttr('href', expectedHref);
  });

  it('renders icon if isActive', done => {
    vm.isActive = true;

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.ic-mobile-issue-close')).not.toBe(null);
      })
      .then(done)
      .catch(done.fail);
  });
});
