import Vue from 'vue';
import CodeComponent from '~/notebook/cells/output/index.vue';

const Component = Vue.extend(CodeComponent);

describe('Output component', () => {
  let vm;
  let json;

  const createComponent = output => {
    vm = new Component({
      propsData: {
        outputs: [].concat(output),
        count: 1,
      },
    });
    vm.$mount();
  };

  beforeEach(() => {
    json = getJSONFixture('blob/notebook/basic.json');
  });

  describe('text output', () => {
    beforeEach(done => {
      createComponent(json.cells[2].outputs[0]);

      setImmediate(() => {
        done();
      });
    });

    it('renders as plain text', () => {
      expect(vm.$el.querySelector('pre')).not.toBeNull();
    });

    it('renders prompt', () => {
      expect(vm.$el.querySelector('.prompt span')).not.toBeNull();
    });
  });

  describe('image output', () => {
    beforeEach(done => {
      createComponent(json.cells[3].outputs[0]);

      setImmediate(() => {
        done();
      });
    });

    it('renders as an image', () => {
      expect(vm.$el.querySelector('img')).not.toBeNull();
    });
  });

  describe('html output', () => {
    it('renders raw HTML', () => {
      createComponent(json.cells[4].outputs[0]);

      expect(vm.$el.querySelector('p')).not.toBeNull();
      expect(vm.$el.querySelectorAll('p').length).toBe(1);
      expect(vm.$el.textContent.trim()).toContain('test');
    });

    it('renders multiple raw HTML outputs', () => {
      createComponent([json.cells[4].outputs[0], json.cells[4].outputs[0]]);

      expect(vm.$el.querySelectorAll('p').length).toBe(2);
    });
  });

  describe('svg output', () => {
    beforeEach(done => {
      createComponent(json.cells[5].outputs[0]);

      setImmediate(() => {
        done();
      });
    });

    it('renders as an svg', () => {
      expect(vm.$el.querySelector('svg')).not.toBeNull();
    });
  });

  describe('default to plain text', () => {
    beforeEach(done => {
      createComponent(json.cells[6].outputs[0]);

      setImmediate(() => {
        done();
      });
    });

    it('renders as plain text', () => {
      expect(vm.$el.querySelector('pre')).not.toBeNull();
      expect(vm.$el.textContent.trim()).toContain('testing');
    });

    it('renders promot', () => {
      expect(vm.$el.querySelector('.prompt span')).not.toBeNull();
    });

    it("renders as plain text when doesn't recognise other types", done => {
      createComponent(json.cells[7].outputs[0]);

      setImmediate(() => {
        expect(vm.$el.querySelector('pre')).not.toBeNull();
        expect(vm.$el.textContent.trim()).toContain('testing');

        done();
      });
    });
  });
});
