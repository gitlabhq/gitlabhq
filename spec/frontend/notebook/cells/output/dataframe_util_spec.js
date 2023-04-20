import { isDataframe, convertHtmlTableToJson } from '~/notebook/cells/output/dataframe_util';
import { outputWithDataframeContent } from '../../mock_data';
import sanitizeTests from './html_sanitize_fixtures';

describe('notebook/cells/output/dataframe_utils', () => {
  describe('isDataframe', () => {
    describe('when output data has no text/html', () => {
      it('is is not a dataframe', () => {
        const input = { data: { 'image/png': ['blah'] } };

        expect(isDataframe(input)).toBe(false);
      });
    });

    describe('when output data has no text/html, but no mention of dataframe', () => {
      it('is is not a dataframe', () => {
        const input = { data: { 'text/html': ['blah'] } };

        expect(isDataframe(input)).toBe(false);
      });
    });

    describe('when output data has text/html, but no mention of dataframe in the first 20 lines', () => {
      it('is is not a dataframe', () => {
        const input = { data: { 'text/html': [...new Array(20).fill('a'), 'dataframe'] } };

        expect(isDataframe(input)).toBe(false);
      });
    });

    describe('when output data has text/html, and includes "dataframe" within the first 20 lines', () => {
      it('is is not a dataframe', () => {
        const input = { data: { 'text/html': ['dataframe'] } };

        expect(isDataframe(input)).toBe(true);
      });
    });
  });

  describe('convertHtmlTableToJson', () => {
    it('converts table correctly', () => {
      const input = outputWithDataframeContent;

      const output = {
        fields: [
          { key: 'index', label: '', sortable: true },
          { key: 'column_1', label: 'column_1', sortable: true },
          { key: 'column_2', label: 'column_2', sortable: true },
        ],
        items: [
          { index: 0, column_1: 'abc de f', column_2: 'a' },
          { index: 1, column_1: 'True', column_2: '0.1' },
        ],
      };

      expect(convertHtmlTableToJson(input)).toEqual(output);
    });

    describe('sanitizes input before parsing table', () => {
      it('sanitizes input html', () => {
        const parser = new DOMParser();
        const spy = jest.spyOn(parser, 'parseFromString');
        const input = 'hello<style>p {width:50%;}</style><script>alert(1)</script>';

        convertHtmlTableToJson(input, parser);

        expect(spy).toHaveBeenCalledWith('hello', 'text/html');
      });
    });

    describe('does not include harmful html', () => {
      const makeDataframeWithHtml = (html) => {
        return [
          '<table border="1" class="dataframe">\n',
          '  <thead>\n',
          '    <tr style="text-align: right;">\n',
          '      <th></th>\n',
          '      <th>column_1</th>\n',
          '    </tr>\n',
          '  </thead>\n',
          '  <tbody>\n',
          '    <tr>\n',
          '      <th>0</th>\n',
          `      <td>${html}</td>\n`,
          '    </tr>\n',
          '  </tbody>\n',
          '</table>\n',
          '</div>',
        ];
      };

      it.each([
        ['table', 0],
        ['style', 1],
        ['iframe', 2],
        ['svg', 3],
      ])('sanitizes output for: %p', (tag, index) => {
        const inputHtml = makeDataframeWithHtml(sanitizeTests[index][1].input);
        const convertedHtml = convertHtmlTableToJson(inputHtml).items[0].column_1;

        expect(convertedHtml).not.toContain(tag);
      });
    });

    describe('when dataframe is invalid', () => {
      it('returns empty', () => {
        const input = [' dataframe', ' blah'];

        expect(convertHtmlTableToJson(input)).toEqual({ fields: [], items: [] });
      });
    });
  });
});
