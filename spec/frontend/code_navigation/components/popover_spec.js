import { shallowMount } from '@vue/test-utils';
import DocLine from '~/code_navigation/components/doc_line.vue';
import Popover from '~/code_navigation/components/popover.vue';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';

const DEFINITION_PATH_PREFIX = 'http://gitlab.com';

const MOCK_CODE_DATA = Object.freeze({
  hover: [
    {
      language: 'javascript',
      tokens: [
        [
          {
            class: 'k',
            value: 'function',
          },
          {
            value: ' main() {',
          },
        ],
        [
          {
            value: '}',
          },
        ],
      ],
    },
  ],
  definition_path: 'test.js',
  definitionLineNumber: 20,
});

const MOCK_DOCS_DATA = Object.freeze({
  hover: [
    {
      language: null,
      value: '```console.log```',
    },
  ],
  definition_path: 'test.js#L20',
});

const MOCK_DATA_WITH_REFERENCES = Object.freeze({
  hover: [
    {
      language: null,
      value: 'console.log',
    },
  ],
  references: [{ path: 'index.js' }, { path: 'app.js' }],
  definition_path: 'test.js#L20',
});

let wrapper;

function factory({ position, data, definitionPathPrefix, blobPath = 'index.js' }) {
  wrapper = shallowMount(Popover, {
    propsData: { position, data, definitionPathPrefix, blobPath },
    stubs: { DocLine, Markdown },
  });
}

describe('Code navigation popover component', () => {
  it('renders popover', () => {
    factory({
      position: { x: 0, y: 0, height: 0 },
      data: MOCK_CODE_DATA,
      definitionPathPrefix: DEFINITION_PATH_PREFIX,
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('srender references tab with empty text when no references exist', () => {
    factory({
      position: { x: 0, y: 0, height: 0 },
      data: MOCK_CODE_DATA,
      definitionPathPrefix: DEFINITION_PATH_PREFIX,
    });

    expect(wrapper.find('[data-testid="references-tab"]').text()).toContain('No references found');
  });

  it('renders link with hash to current file', () => {
    factory({
      position: { x: 0, y: 0, height: 0 },
      data: MOCK_CODE_DATA,
      definitionPathPrefix: DEFINITION_PATH_PREFIX,
      blobPath: 'test.js',
    });

    expect(wrapper.find('[data-testid="go-to-definition-btn"]').attributes('href')).toBe('#L20');
  });

  it('renders list of references', () => {
    factory({
      position: { x: 0, y: 0, height: 0 },
      data: MOCK_DATA_WITH_REFERENCES,
      definitionPathPrefix: DEFINITION_PATH_PREFIX,
    });

    expect(wrapper.find('[data-testid="references-tab"]').exists()).toBe(true);
    expect(wrapper.findAll('[data-testid="reference-link"]').length).toBe(2);
  });

  describe('code output', () => {
    it('renders code output', () => {
      factory({
        position: { x: 0, y: 0, height: 0 },
        data: MOCK_CODE_DATA,
        definitionPathPrefix: DEFINITION_PATH_PREFIX,
      });

      expect(wrapper.findComponent({ ref: 'code-output' }).exists()).toBe(true);
      expect(wrapper.findComponent({ ref: 'doc-output' }).exists()).toBe(false);
    });
  });

  describe('documentation output', () => {
    it('renders code output', () => {
      factory({
        position: { x: 0, y: 0, height: 0 },
        data: MOCK_DOCS_DATA,
        definitionPathPrefix: DEFINITION_PATH_PREFIX,
      });

      expect(wrapper.findComponent({ ref: 'code-output' }).exists()).toBe(false);
      expect(wrapper.findComponent({ ref: 'doc-output' }).exists()).toBe(true);
    });

    it('renders markdown', () => {
      factory({
        position: { x: 0, y: 0, height: 0 },
        data: MOCK_DOCS_DATA,
        definitionPathPrefix: DEFINITION_PATH_PREFIX,
      });

      expect(wrapper.findComponent(Markdown).exists()).toBe(true);
    });
  });
});
