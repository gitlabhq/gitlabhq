import { shallowMount } from '@vue/test-utils';
import Popover from '~/code_navigation/components/popover.vue';

const DEFINITION_PATH_PREFIX = 'http://gitlab.com';

const MOCK_CODE_DATA = Object.freeze({
  hover: [
    {
      language: 'javascript',
      value: 'console.log',
    },
  ],
  definition_path: 'test.js#L20',
});

const MOCK_DOCS_DATA = Object.freeze({
  hover: [
    {
      language: null,
      value: 'console.log',
    },
  ],
  definition_path: 'test.js#L20',
});

let wrapper;

function factory({ position, data, definitionPathPrefix, blobPath = 'index.js' }) {
  wrapper = shallowMount(Popover, {
    propsData: { position, data, definitionPathPrefix, blobPath },
  });
}

describe('Code navigation popover component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders popover', () => {
    factory({
      position: { x: 0, y: 0, height: 0 },
      data: MOCK_CODE_DATA,
      definitionPathPrefix: DEFINITION_PATH_PREFIX,
    });

    expect(wrapper.element).toMatchSnapshot();
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

  describe('code output', () => {
    it('renders code output', () => {
      factory({
        position: { x: 0, y: 0, height: 0 },
        data: MOCK_CODE_DATA,
        definitionPathPrefix: DEFINITION_PATH_PREFIX,
      });

      expect(wrapper.find({ ref: 'code-output' }).exists()).toBe(true);
      expect(wrapper.find({ ref: 'doc-output' }).exists()).toBe(false);
    });
  });

  describe('documentation output', () => {
    it('renders code output', () => {
      factory({
        position: { x: 0, y: 0, height: 0 },
        data: MOCK_DOCS_DATA,
        definitionPathPrefix: DEFINITION_PATH_PREFIX,
      });

      expect(wrapper.find({ ref: 'code-output' }).exists()).toBe(false);
      expect(wrapper.find({ ref: 'doc-output' }).exists()).toBe(true);
    });
  });
});
