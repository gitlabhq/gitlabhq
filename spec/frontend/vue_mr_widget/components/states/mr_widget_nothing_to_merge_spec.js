import Vue from 'vue';
import NothingToMerge from '~/vue_merge_request_widget/components/states/nothing_to_merge.vue';

describe('NothingToMerge', () => {
  describe('template', () => {
    const Component = Vue.extend(NothingToMerge);
    const newBlobPath = '/foo';
    const vm = new Component({
      el: document.createElement('div'),
      propsData: {
        mr: { newBlobPath },
      },
    });

    it('should have correct elements', () => {
      expect(vm.$el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(vm.$el.querySelector('[data-testid="createFileButton"]').href).toContain(newBlobPath);
      expect(vm.$el.innerText).toContain('Use merge requests to propose changes to your project');
    });

    it('should not show new blob link if there is no link available', () => {
      vm.mr.newBlobPath = null;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('[data-testid="createFileButton"]')).toEqual(null);
      });
    });
  });
});
