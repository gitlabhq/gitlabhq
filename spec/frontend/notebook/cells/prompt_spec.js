import Vue from 'vue';
import PromptComponent from '~/notebook/cells/prompt.vue';

const Component = Vue.extend(PromptComponent);

describe('Prompt component', () => {
  let vm;

  describe('input', () => {
    beforeEach((done) => {
      vm = new Component({
        propsData: {
          type: 'In',
          count: 1,
        },
      });
      vm.$mount();

      setImmediate(() => {
        done();
      });
    });

    it('renders in label', () => {
      expect(vm.$el.textContent.trim()).toContain('In');
    });

    it('renders count', () => {
      expect(vm.$el.textContent.trim()).toContain('1');
    });
  });

  describe('output', () => {
    beforeEach((done) => {
      vm = new Component({
        propsData: {
          type: 'Out',
          count: 1,
        },
      });
      vm.$mount();

      setImmediate(() => {
        done();
      });
    });

    it('renders in label', () => {
      expect(vm.$el.textContent.trim()).toContain('Out');
    });

    it('renders count', () => {
      expect(vm.$el.textContent.trim()).toContain('1');
    });
  });
});
