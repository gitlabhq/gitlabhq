import Vue from 'vue';
import '~/behaviors/markdown/render_gfm';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import { createStore } from '~/ide/stores';
import RightPane from '~/ide/components/panes/right.vue';
import { rightSidebarViews } from '~/ide/constants';

describe('IDE right pane', () => {
  let Component;
  let vm;

  beforeAll(() => {
    Component = Vue.extend(RightPane);
  });

  beforeEach(() => {
    const store = createStore();

    vm = createComponentWithStore(Component, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('active', () => {
    it('renders merge request button as active', done => {
      vm.$store.state.rightPane.isOpen = true;
      vm.$store.state.rightPane.currentView = rightSidebarViews.mergeRequestInfo.name;
      vm.$store.state.currentMergeRequestId = '123';
      vm.$store.state.currentProjectId = 'gitlab-ce';
      vm.$store.state.currentMergeRequestId = 1;
      vm.$store.state.projects['gitlab-ce'] = {
        mergeRequests: {
          1: {
            iid: 1,
            title: 'Testing',
            title_html: '<span class="title-html">Testing</span>',
            description: 'Description',
            description_html: '<p class="description-html">Description HTML</p>',
          },
        },
      };

      vm.$nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.ide-sidebar-link.active')).not.toBe(null);
          expect(
            vm.$el.querySelector('.ide-sidebar-link.active').getAttribute('data-original-title'),
          ).toBe('Merge Request');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('click', () => {
    beforeEach(() => {
      jest.spyOn(vm, 'open').mockReturnValue();
    });

    it('sets view to merge request', done => {
      vm.$store.state.currentMergeRequestId = '123';

      vm.$nextTick(() => {
        vm.$el.querySelector('.ide-sidebar-link').click();

        expect(vm.open).toHaveBeenCalledWith(rightSidebarViews.mergeRequestInfo);

        done();
      });
    });
  });

  describe('live preview', () => {
    it('renders live preview button', done => {
      Vue.set(vm.$store.state.entries, 'package.json', {
        name: 'package.json',
      });
      vm.$store.state.clientsidePreviewEnabled = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('button[aria-label="Live preview"]')).not.toBeNull();

        done();
      });
    });
  });
});
