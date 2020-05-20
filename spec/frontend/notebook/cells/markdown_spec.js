import Vue from 'vue';
import katex from 'katex';
import MarkdownComponent from '~/notebook/cells/markdown.vue';

const Component = Vue.extend(MarkdownComponent);

window.katex = katex;

describe('Markdown component', () => {
  let vm;
  let cell;
  let json;

  beforeEach(() => {
    json = getJSONFixture('blob/notebook/basic.json');

    // eslint-disable-next-line prefer-destructuring
    cell = json.cells[1];

    vm = new Component({
      propsData: {
        cell,
      },
    });
    vm.$mount();

    return vm.$nextTick();
  });

  it('does not render promot', () => {
    expect(vm.$el.querySelector('.prompt span')).toBeNull();
  });

  it('does not render the markdown text', () => {
    expect(vm.$el.querySelector('.markdown').innerHTML.trim()).not.toEqual(cell.source.join(''));
  });

  it('renders the markdown HTML', () => {
    expect(vm.$el.querySelector('.markdown h1')).not.toBeNull();
  });

  it('sanitizes output', () => {
    Object.assign(cell, {
      source: [
        '[XSS](data:text/html;base64,PHNjcmlwdD5hbGVydChkb2N1bWVudC5kb21haW4pPC9zY3JpcHQ+Cg==)\n',
      ],
    });

    return vm.$nextTick().then(() => {
      expect(vm.$el.querySelector('a').getAttribute('href')).toBeNull();
    });
  });

  describe('katex', () => {
    beforeEach(() => {
      json = getJSONFixture('blob/notebook/math.json');
    });

    it('renders multi-line katex', () => {
      vm = new Component({
        propsData: {
          cell: json.cells[0],
        },
      }).$mount();

      return vm.$nextTick().then(() => {
        expect(vm.$el.querySelector('.katex')).not.toBeNull();
      });
    });

    it('renders inline katex', () => {
      vm = new Component({
        propsData: {
          cell: json.cells[1],
        },
      }).$mount();

      return vm.$nextTick().then(() => {
        expect(vm.$el.querySelector('p:first-child .katex')).not.toBeNull();
      });
    });

    it('renders multiple inline katex', () => {
      vm = new Component({
        propsData: {
          cell: json.cells[1],
        },
      }).$mount();

      return vm.$nextTick().then(() => {
        expect(vm.$el.querySelectorAll('p:nth-child(2) .katex').length).toBe(4);
      });
    });

    it('output cell in case of katex error', () => {
      vm = new Component({
        propsData: {
          cell: {
            cell_type: 'markdown',
            metadata: {},
            source: ['Some invalid $a & b$ inline formula $b & c$\n', '\n'],
          },
        },
      }).$mount();

      return vm.$nextTick().then(() => {
        // expect one paragraph with no katex formula in it
        expect(vm.$el.querySelectorAll('p').length).toBe(1);
        expect(vm.$el.querySelectorAll('p .katex').length).toBe(0);
      });
    });

    it('output cell and render remaining formula in case of katex error', () => {
      vm = new Component({
        propsData: {
          cell: {
            cell_type: 'markdown',
            metadata: {},
            source: ['An invalid $a & b$ inline formula and a vaild one $b = c$\n', '\n'],
          },
        },
      }).$mount();

      return vm.$nextTick().then(() => {
        // expect one paragraph with no katex formula in it
        expect(vm.$el.querySelectorAll('p').length).toBe(1);
        expect(vm.$el.querySelectorAll('p .katex').length).toBe(1);
      });
    });

    it('renders math formula in list object', () => {
      vm = new Component({
        propsData: {
          cell: {
            cell_type: 'markdown',
            metadata: {},
            source: ["- list with inline $a=2$ inline formula $a' + b = c$\n", '\n'],
          },
        },
      }).$mount();

      return vm.$nextTick().then(() => {
        // expect one list with a katex formula in it
        expect(vm.$el.querySelectorAll('li').length).toBe(1);
        expect(vm.$el.querySelectorAll('li .katex').length).toBe(2);
      });
    });

    it("renders math formula with tick ' in it", () => {
      vm = new Component({
        propsData: {
          cell: {
            cell_type: 'markdown',
            metadata: {},
            source: ["- list with inline $a=2$ inline formula $a' + b = c$\n", '\n'],
          },
        },
      }).$mount();

      return vm.$nextTick().then(() => {
        // expect one list with a katex formula in it
        expect(vm.$el.querySelectorAll('li').length).toBe(1);
        expect(vm.$el.querySelectorAll('li .katex').length).toBe(2);
      });
    });
  });
});
