import Vue from 'vue';
import Notebook from '~/notebook/index.vue';

const Component = Vue.extend(Notebook);

describe('Notebook component', () => {
  let vm;
  let json;
  let jsonWithWorksheet;

  beforeEach(() => {
    json = getJSONFixture('blob/notebook/basic.json');
    jsonWithWorksheet = getJSONFixture('blob/notebook/worksheets.json');
  });

  describe('without JSON', () => {
    beforeEach(done => {
      vm = new Component({
        propsData: {
          notebook: {},
        },
      });
      vm.$mount();

      setImmediate(() => {
        done();
      });
    });

    it('does not render', () => {
      expect(vm.$el.tagName).toBeUndefined();
    });
  });

  describe('with JSON', () => {
    beforeEach(done => {
      vm = new Component({
        propsData: {
          notebook: json,
          codeCssClass: 'js-code-class',
        },
      });
      vm.$mount();

      setImmediate(() => {
        done();
      });
    });

    it('renders cells', () => {
      expect(vm.$el.querySelectorAll('.cell').length).toBe(json.cells.length);
    });

    it('renders markdown cell', () => {
      expect(vm.$el.querySelector('.markdown')).not.toBeNull();
    });

    it('renders code cell', () => {
      expect(vm.$el.querySelector('pre')).not.toBeNull();
    });

    it('add code class to code blocks', () => {
      expect(vm.$el.querySelector('.js-code-class')).not.toBeNull();
    });
  });

  describe('with worksheets', () => {
    beforeEach(done => {
      vm = new Component({
        propsData: {
          notebook: jsonWithWorksheet,
          codeCssClass: 'js-code-class',
        },
      });
      vm.$mount();

      setImmediate(() => {
        done();
      });
    });

    it('renders cells', () => {
      expect(vm.$el.querySelectorAll('.cell').length).toBe(
        jsonWithWorksheet.worksheets[0].cells.length,
      );
    });

    it('renders markdown cell', () => {
      expect(vm.$el.querySelector('.markdown')).not.toBeNull();
    });

    it('renders code cell', () => {
      expect(vm.$el.querySelector('pre')).not.toBeNull();
    });

    it('add code class to code blocks', () => {
      expect(vm.$el.querySelector('.js-code-class')).not.toBeNull();
    });
  });
});
