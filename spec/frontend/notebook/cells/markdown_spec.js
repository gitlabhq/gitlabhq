import { mount } from '@vue/test-utils';
import katex from 'katex';
import { nextTick } from 'vue';
import markdownTableJson from 'test_fixtures/blob/notebook/markdown-table.json';
import basicJson from 'test_fixtures/blob/notebook/basic.json';
import mathJson from 'test_fixtures/blob/notebook/math.json';
import MarkdownComponent from '~/notebook/cells/markdown.vue';
import Prompt from '~/notebook/cells/prompt.vue';

window.katex = katex;

function buildCellComponent(cell, relativePath = '', hidePrompt) {
  return mount(MarkdownComponent, {
    propsData: {
      cell,
      hidePrompt,
    },
    provide: {
      relativeRawPath: relativePath,
    },
  });
}

function buildMarkdownComponent(markdownContent, relativePath = '') {
  return buildCellComponent(
    {
      cell_type: 'markdown',
      metadata: {},
      source: markdownContent,
    },
    relativePath,
  );
}

describe('Markdown component', () => {
  let wrapper;
  let cell;
  let json;

  beforeEach(async () => {
    json = basicJson;

    // eslint-disable-next-line prefer-destructuring
    cell = json.cells[1];

    wrapper = buildCellComponent(cell);

    await nextTick();
  });

  const findPrompt = () => wrapper.findComponent(Prompt);

  it('renders a prompt by default', () => {
    expect(findPrompt().exists()).toBe(true);
  });

  it('does not render a prompt if hidePrompt is true', () => {
    wrapper = buildCellComponent(cell, '', true);
    expect(findPrompt().exists()).toBe(false);
  });

  it('does not render the markdown text', () => {
    expect(wrapper.vm.$el.querySelector('.markdown').innerHTML.trim()).not.toEqual(
      cell.source.join(''),
    );
  });

  it('renders the markdown HTML', () => {
    expect(wrapper.vm.$el.querySelector('.markdown h1')).not.toBeNull();
  });

  it('renders the markdown HTML when source is not an array', () => {
    cell = {
      cell_type: 'markdown',
      source: '# test',
    };

    wrapper = buildCellComponent(cell);

    expect(wrapper.vm.$el.querySelector('.markdown h1')).not.toBeNull();
  });

  it('sanitizes Markdown output', async () => {
    Object.assign(cell, {
      source: [
        '[XSS](data:text/html;base64,PHNjcmlwdD5hbGVydChkb2N1bWVudC5kb21haW4pPC9zY3JpcHQ+Cg==)\n',
      ],
    });

    await nextTick();
    expect(wrapper.vm.$el.querySelector('a').getAttribute('href')).toBeNull();
  });

  it('sanitizes HTML', async () => {
    const findLink = () => wrapper.vm.$el.querySelector('.xss-link');
    Object.assign(cell, {
      source: ['<a href="test.js" data-remote=true data-type="script" class="xss-link">XSS</a>\n'],
    });

    await nextTick();
    expect(findLink().dataset.remote).toBeUndefined();
    expect(findLink().dataset.type).toBeUndefined();
  });

  describe('When parsing images', () => {
    it.each([
      [
        'for relative images in root folder, it does',
        '![](local_image.png)\n',
        'src="/raw/local_image',
      ],
      [
        'for relative images in child folders, it does',
        '![](data/local_image.png)\n',
        'src="/raw/data',
      ],
      ["for embedded images, it doesn't", '![](data:image/jpeg;base64)\n', 'src="data:'],
      ["for images urls, it doesn't", '![](http://image.png)\n', 'src="http:'],
    ])('%s', async ([testMd, mustContain]) => {
      wrapper = buildMarkdownComponent([testMd], '/raw/');

      await nextTick();

      expect(wrapper.vm.$el.innerHTML).toContain(mustContain);
    });
  });

  describe('tables', () => {
    beforeEach(() => {
      json = markdownTableJson;
    });

    it('renders images and text', async () => {
      wrapper = buildCellComponent(json.cells[0]);

      await nextTick();
      const images = wrapper.vm.$el.querySelectorAll('img');
      expect(images.length).toBe(5);

      const columns = wrapper.vm.$el.querySelectorAll('td');
      expect(columns.length).toBe(6);

      expect(columns[0].textContent).toEqual('Hello ');
      expect(columns[1].textContent).toEqual('Test ');
      expect(columns[2].textContent).toEqual('World ');
      expect(columns[3].textContent).toEqual('Fake ');
      expect(columns[4].textContent).toEqual('External image: ');
      expect(columns[5].textContent).toEqual('Empty');

      expect(columns[0].innerHTML).toContain('<img src="data:image/jpeg;base64');
      expect(columns[1].innerHTML).toContain('<img src="data:image/png;base64');
      expect(columns[2].innerHTML).toContain('<img src="data:image/jpeg;base64');
      expect(columns[3].innerHTML).toContain('<img src="attachment:bogus">');
      expect(columns[4].innerHTML).toContain('<img src="https://www.google.com/');
    });
  });

  describe('katex', () => {
    beforeEach(() => {
      json = mathJson;
    });

    it('renders multi-line katex', async () => {
      wrapper = buildCellComponent(json.cells[0]);

      await nextTick();
      expect(wrapper.vm.$el.querySelector('.katex')).not.toBeNull();
    });

    it('renders inline katex', async () => {
      wrapper = buildCellComponent(json.cells[1]);

      await nextTick();
      expect(wrapper.vm.$el.querySelector('p:first-child .katex')).not.toBeNull();
    });

    it('renders multiple inline katex', async () => {
      wrapper = buildCellComponent(json.cells[1]);

      await nextTick();
      expect(wrapper.vm.$el.querySelectorAll('p:nth-child(2) .katex')).toHaveLength(4);
    });

    it('output cell in case of katex error', async () => {
      wrapper = buildMarkdownComponent(['Some invalid $a & b$ inline formula $b & c$\n', '\n']);

      await nextTick();
      // expect one paragraph with no katex formula in it
      expect(wrapper.vm.$el.querySelectorAll('p')).toHaveLength(1);
      expect(wrapper.vm.$el.querySelectorAll('p .katex')).toHaveLength(0);
    });

    it('output cell and render remaining formula in case of katex error', async () => {
      wrapper = buildMarkdownComponent([
        'An invalid $a & b$ inline formula and a vaild one $b = c$\n',
        '\n',
      ]);

      await nextTick();
      // expect one paragraph with no katex formula in it
      expect(wrapper.vm.$el.querySelectorAll('p')).toHaveLength(1);
      expect(wrapper.vm.$el.querySelectorAll('p .katex')).toHaveLength(1);
    });

    it('renders math formula in list object', async () => {
      wrapper = buildMarkdownComponent([
        "- list with inline $a=2$ inline formula $a' + b = c$\n",
        '\n',
      ]);

      await nextTick();
      // expect one list with a katex formula in it
      expect(wrapper.vm.$el.querySelectorAll('li')).toHaveLength(1);
      expect(wrapper.vm.$el.querySelectorAll('li .katex')).toHaveLength(2);
    });

    it("renders math formula with tick ' in it", async () => {
      wrapper = buildMarkdownComponent([
        "- list with inline $a=2$ inline formula $a' + b = c$\n",
        '\n',
      ]);

      await nextTick();
      // expect one list with a katex formula in it
      expect(wrapper.vm.$el.querySelectorAll('li')).toHaveLength(1);
      expect(wrapper.vm.$el.querySelectorAll('li .katex')).toHaveLength(2);
    });

    it('renders math formula with less-than-operator < in it', async () => {
      wrapper = buildMarkdownComponent([
        '- list with inline $a=2$ inline formula $a + b < c$\n',
        '\n',
      ]);

      await nextTick();
      // expect one list with a katex formula in it
      expect(wrapper.vm.$el.querySelectorAll('li')).toHaveLength(1);
      expect(wrapper.vm.$el.querySelectorAll('li .katex')).toHaveLength(2);
    });

    it('renders math formula with greater-than-operator > in it', async () => {
      wrapper = buildMarkdownComponent([
        '- list with inline $a=2$ inline formula $a + b > c$\n',
        '\n',
      ]);

      await nextTick();
      // expect one list with a katex formula in it
      expect(wrapper.vm.$el.querySelectorAll('li')).toHaveLength(1);
      expect(wrapper.vm.$el.querySelectorAll('li .katex')).toHaveLength(2);
    });
  });
});
