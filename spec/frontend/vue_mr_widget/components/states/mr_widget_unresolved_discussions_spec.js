import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import UnresolvedDiscussions from '~/vue_merge_request_widget/components/states/unresolved_discussions.vue';
import { TEST_HOST } from 'helpers/test_constants';

describe('UnresolvedDiscussions', () => {
  const Component = Vue.extend(UnresolvedDiscussions);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with threads path', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        mr: {
          createIssueToResolveDiscussionsPath: TEST_HOST,
        },
      });
    });

    it('should have correct elements', () => {
      expect(vm.$el.innerText).toContain(
        'There are unresolved threads. Please resolve these threads',
      );

      expect(vm.$el.innerText).toContain('Create an issue to resolve them later');
      expect(vm.$el.querySelector('.js-create-issue').getAttribute('href')).toEqual(TEST_HOST);
    });
  });

  describe('without threads path', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { mr: {} });
    });

    it('should not show create issue link if user cannot create issue', () => {
      expect(vm.$el.innerText).toContain(
        'There are unresolved threads. Please resolve these threads',
      );

      expect(vm.$el.querySelector('.js-create-issue')).toEqual(null);
    });
  });
});
