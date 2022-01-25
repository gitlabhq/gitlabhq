import Vue, { nextTick } from 'vue';
import fixture from 'test_fixtures/blob/notebook/basic.json';
import CodeComponent from '~/notebook/cells/code.vue';

const Component = Vue.extend(CodeComponent);

describe('Code component', () => {
  let vm;

  let json;

  beforeEach(() => {
    // Clone fixture as it could be modified by tests
    json = JSON.parse(JSON.stringify(fixture));
  });

  const setupComponent = (cell) => {
    const comp = new Component({
      propsData: {
        cell,
      },
    });
    comp.$mount();
    return comp;
  };

  describe('without output', () => {
    beforeEach((done) => {
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
    beforeEach((done) => {
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

  describe('with string for output', () => {
    // NBFormat Version 4.1 allows outputs.text to be a string
    beforeEach(async () => {
      const cell = json.cells[2];
      cell.outputs[0].text = cell.outputs[0].text.join('');

      vm = setupComponent(cell);
      await nextTick();
    });

    it('does not render output prompt', () => {
      expect(vm.$el.querySelectorAll('.prompt').length).toBe(2);
    });

    it('renders output cell', () => {
      expect(vm.$el.querySelector('.output')).toBeDefined();
    });
  });

  describe('with string for cell.source', () => {
    beforeEach(async () => {
      const cell = json.cells[0];
      cell.source = cell.source.join('');

      vm = setupComponent(cell);
      await nextTick();
    });

    it('renders the same input as when cell.source is an array', () => {
      const expected = "console.log('test')";

      expect(vm.$el.querySelector('.input').innerText).toContain(expected);
    });
  });
});
