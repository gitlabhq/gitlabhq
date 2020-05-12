import Vue from 'vue';
import CodeComponent from '~/notebook/cells/code.vue';

const Component = Vue.extend(CodeComponent);

describe('Code component', () => {
  let vm;
  let json;

  beforeEach(() => {
    json = getJSONFixture('blob/notebook/basic.json');
  });

  const setupComponent = cell => {
    const comp = new Component({
      propsData: {
        cell,
      },
    });
    comp.$mount();
    return comp;
  };

  describe('without output', () => {
    beforeEach(done => {
      vm = setupComponent(json.cells[0]);

      setImmediate(() => {
        done();
      });
    });

    it('does not render output prompt', () => {
      expect(vm.$el.querySelectorAll('.prompt').length).toBe(1);
    });
  });

  describe('with output', () => {
    beforeEach(done => {
      vm = setupComponent(json.cells[2]);

      setImmediate(() => {
        done();
      });
    });

    it('does not render output prompt', () => {
      expect(vm.$el.querySelectorAll('.prompt').length).toBe(2);
    });

    it('renders output cell', () => {
      expect(vm.$el.querySelector('.output')).toBeDefined();
    });
  });

  describe('with string for cell.source', () => {
    beforeEach(done => {
      const cell = json.cells[0];
      cell.source = cell.source.join('');

      vm = setupComponent(cell);

      setImmediate(() => {
        done();
      });
    });

    it('renders the same input as when cell.source is an array', () => {
      const expected = "console.log('test')";

      expect(vm.$el.querySelector('.input').innerText).toContain(expected);
    });
  });
});
