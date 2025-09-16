import { Plugin as MockPMPlugin } from '@tiptap/pm/state';
import Suggestions from '~/content_editor/extensions/suggestions';
import { createTestEditor } from '../test_utils';

jest.mock('@tiptap/suggestion', () => {
  const captured = [];
  const mock = (config) => {
    captured.push(config);
    return new MockPMPlugin({ props: { items: config.items } });
  };
  mock.getCaptured = () => captured;
  return mock;
});

describe('content_editor/extensions/suggestions', () => {
  let editor;

  const buildEditorWithExtension = (autocompleteResults) => {
    const mockAutocompleteHelper = {
      getDataSource: jest.fn().mockReturnValue({
        search: jest.fn().mockResolvedValue(autocompleteResults),
      }),
    };

    const serializer = { serialize: jest.fn().mockReturnValue('/command') };

    editor = createTestEditor({
      extensions: [
        Suggestions.configure({ autocompleteHelper: mockAutocompleteHelper, serializer }),
      ],
    });
  };

  const mockEditorCtx = () => ({
    state: {
      doc: {
        slice: jest.fn().mockReturnValue({ content: {} }),
      },
      selection: { to: 10 },
    },
    isActive: jest.fn().mockReturnValue(false),
  });

  const getSlashItems = () => {
    const SuggestionMock = jest.requireMock('@tiptap/suggestion');
    const configs = SuggestionMock.getCaptured();
    const slashConfig = configs.find((c) => c.char === '/');
    if (!slashConfig) throw new Error('Slash suggestion config not captured');
    return slashConfig.items;
  };

  afterEach(() => {
    const SuggestionMock = jest.requireMock('@tiptap/suggestion');
    SuggestionMock.getCaptured().length = 0;

    editor.destroy();
  });

  describe('quick actions alphabetical sorting', () => {
    it('sorts quick action commands alphabetically by name', async () => {
      buildEditorWithExtension([
        { name: 'zebra', description: 'Zebra command' },
        { name: 'alpha', description: 'Alpha command' },
        { name: 'beta', description: 'Beta command' },
      ]);

      const items = getSlashItems();
      const result = await items({ query: '', editor: mockEditorCtx() });

      expect(result.map((r) => r.name)).toEqual(['alpha', 'beta', 'zebra']);
    });

    it('places null/undefined names at the end, preserving order among them', async () => {
      buildEditorWithExtension([
        { name: 'zebra', description: 'Zebra command' },
        { name: null, description: 'Null command' },
        { name: 'alpha', description: 'Alpha command' },
        { name: undefined, description: 'Undefined command' },
      ]);

      const items = getSlashItems();
      const result = await items({ query: '', editor: mockEditorCtx() });

      expect(result.map((r) => r.name)).toEqual(['alpha', 'zebra', null, undefined]);
    });

    it('does not re-sort when query is present; preserves data source order', async () => {
      buildEditorWithExtension([
        { name: 'beta', description: 'Beta command' },
        { name: 'alpha', description: 'Alpha command' },
        { name: 'zebra', description: 'Zebra command' },
      ]);

      const items = getSlashItems();
      const result = await items({ query: 'a', editor: mockEditorCtx() });

      expect(result.map((r) => r.name)).toEqual(['beta', 'alpha', 'zebra']);
    });
  });
});
