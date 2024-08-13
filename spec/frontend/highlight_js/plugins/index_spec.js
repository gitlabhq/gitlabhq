import { highlightPlugins, registerPlugins } from '~/highlight_js/plugins';
import wrapChildNodes from '~/vue_shared/components/source_viewer/plugins/wrap_child_nodes';
import wrapBidiChars from '~/vue_shared/components/source_viewer/plugins/wrap_bidi_chars';

jest.mock('~/vue_shared/components/source_viewer/plugins/wrap_child_nodes', () => 'wrapChildNodes');
jest.mock('~/vue_shared/components/source_viewer/plugins/wrap_bidi_chars', () => 'wrapBidiChars');
jest.mock('~/vue_shared/components/source_viewer/plugins/wrap_lines', () => 'wrapLines');

describe('index.js', () => {
  describe('highlightPlugins', () => {
    it('returns correct plugins without wrapping lines', () => {
      const result = highlightPlugins('javascript', 'const x = 5;', false);

      expect(result).toHaveLength(3);
      expect(result[0]).toBe(wrapChildNodes);
      expect(result[1]).toBe(wrapBidiChars);
      expect(typeof result[2]).toBe('function');
    });

    it('adds wrapLines when shouldWrapLines is true', () => {
      const withoutWrapLines = highlightPlugins('js', 'code', false);
      const withWrapLines = highlightPlugins('js', 'code', true);

      expect(withoutWrapLines).not.toContain('wrapLines');
      expect(withWrapLines).toContain('wrapLines');
      expect(withWrapLines.length).toBe(withoutWrapLines.length + 1);
    });
  });

  describe('registerPlugins', () => {
    let mockHljs;

    beforeEach(() => {
      mockHljs = { addPlugin: jest.fn() };
    });

    it('registers each plugin with hljs', () => {
      const mockPlugins = [jest.fn(), jest.fn()];
      registerPlugins(mockHljs, mockPlugins);

      expect(mockHljs.addPlugin).toHaveBeenCalledTimes(2);
      mockPlugins.forEach((plugin) => {
        expect(mockHljs.addPlugin).toHaveBeenCalledWith({
          'after:highlight': plugin,
        });
      });
    });

    it('does nothing when plugins array is empty', () => {
      registerPlugins(mockHljs, []);
      expect(mockHljs.addPlugin).not.toHaveBeenCalled();
    });

    it('does nothing when plugins is null or undefined', () => {
      registerPlugins(mockHljs, null);
      registerPlugins(mockHljs, undefined);
      expect(mockHljs.addPlugin).not.toHaveBeenCalled();
    });
  });
});
