import Vue from 'vue';
import CodeComponent from '~/notebook/cells/output/index.vue';

const Component = Vue.extend(CodeComponent);

describe('Output component', () => {
  let vm;
  let json;

  const createComponent = (output) => {
    vm = new Component({
      propsData: {
        outputs: [].concat(output),
        count: 1,
      },
    });
    vm.$mount();
  };

  beforeEach(() => {
    // This is the output after rendering a jupyter notebook
    json = getJSONFixture('blob/notebook/basic.json');
  });

  describe('text output', () => {
    beforeEach((done) => {
      const textType = json.cells[2];
      createComponent(textType.outputs[0]);

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
    beforeEach((done) => {
      const imageType = json.cells[3];
      createComponent(imageType.outputs[0]);

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
      const htmlType = json.cells[4];
      createComponent(htmlType.outputs[0]);

      expect(vm.$el.querySelector('p')).not.toBeNull();
      expect(vm.$el.querySelectorAll('p')).toHaveLength(1);
      expect(vm.$el.textContent.trim()).toContain('test');
    });

    it('renders multiple raw HTML outputs', () => {
      const htmlType = json.cells[4];
      createComponent([htmlType.outputs[0], htmlType.outputs[0]]);

      expect(vm.$el.querySelectorAll('p')).toHaveLength(2);
    });
  });

  describe('LaTeX output', () => {
    it('renders LaTeX', () => {
      const output = {
        data: {
          'text/latex': ['$$F(k) = \\int_{-\\infty}^{\\infty} f(x) e^{2\\pi i k} dx$$'],
          'text/plain': ['<IPython.core.display.Latex object>'],
        },
        metadata: {},
        output_type: 'display_data',
      };
      createComponent(output);

      expect(vm.$el.querySelector('.MathJax')).not.toBeNull();
    });
  });

  describe('svg output', () => {
    beforeEach((done) => {
      const svgType = json.cells[5];
      createComponent(svgType.outputs[0]);

      setImmediate(() => {
        done();
      });
    });

    it('renders as an svg', () => {
      expect(vm.$el.querySelector('svg')).not.toBeNull();
    });
  });

  describe('default to plain text', () => {
    beforeEach((done) => {
      const unknownType = json.cells[6];
      createComponent(unknownType.outputs[0]);

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

    it("renders as plain text when doesn't recognise other types", (done) => {
      const unknownType = json.cells[7];
      createComponent(unknownType.outputs[0]);

      setImmediate(() => {
        expect(vm.$el.querySelector('pre')).not.toBeNull();
        expect(vm.$el.textContent.trim()).toContain('testing');

        done();
      });
    });
  });
});
