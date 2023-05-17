import { mount } from '@vue/test-utils';
import fixture from 'test_fixtures/blob/notebook/basic.json';
import Code from '~/notebook/cells/code.vue';

describe('Code component', () => {
  let wrapper;
  let json;

  const mountComponent = (cell) => mount(Code, { propsData: { cell } });

  beforeEach(() => {
    // Clone fixture as it could be modified by tests
    json = JSON.parse(JSON.stringify(fixture));
  });

  describe('without output', () => {
    beforeEach(() => {
      wrapper = mountComponent(json.cells[0]);
    });

    it('does not render output prompt', () => {
      expect(wrapper.findAll('.prompt')).toHaveLength(1);
    });
  });

  describe('with output', () => {
    beforeEach(() => {
      wrapper = mountComponent(json.cells[2]);
    });

    it('does not render output prompt', () => {
      expect(wrapper.findAll('.prompt')).toHaveLength(2);
    });

    it('renders output cell', () => {
      expect(wrapper.find('.output').exists()).toBe(true);
    });
  });

  describe('with string for output', () => {
    // NBFormat Version 4.1 allows outputs.text to be a string
    beforeEach(() => {
      const cell = json.cells[2];
      cell.outputs[0].text = cell.outputs[0].text.join('');

      wrapper = mountComponent(cell);
    });

    it('does not render output prompt', () => {
      expect(wrapper.findAll('.prompt')).toHaveLength(2);
    });

    it('renders output cell', () => {
      expect(wrapper.find('.output').exists()).toBe(true);
    });
  });

  describe('with string for cell.source', () => {
    beforeEach(() => {
      const cell = json.cells[0];
      cell.source = cell.source.join('');
      wrapper = mountComponent(cell);
    });

    it('renders the same input as when cell.source is an array', () => {
      expect(wrapper.find('.input').text()).toContain("console.log('test')");
    });
  });
});
