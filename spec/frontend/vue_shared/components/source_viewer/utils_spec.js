import { setHTMLFixture } from 'helpers/fixtures';
import {
  calculateBlameOffset,
  shouldRender,
  toggleBlameLineBorders,
  hasBlameDataForChunk,
} from '~/vue_shared/components/source_viewer/utils';
import { SOURCE_CODE_CONTENT_MOCK, BLAME_DATA_MOCK } from './mock_data';

describe('SourceViewer utils', () => {
  beforeEach(() => setHTMLFixture(SOURCE_CODE_CONTENT_MOCK));

  const findContent = () => document.querySelector('.content');

  describe('calculateBlameOffset', () => {
    it('returns an offset of zero if line number === 1', () => {
      expect(calculateBlameOffset(1)).toBe('0px');
    });

    it('calculates an offset for the blame component', () => {
      const { offsetTop } = document.querySelector('#LC3');
      expect(calculateBlameOffset(3)).toBe(`${offsetTop}px`);
    });
  });

  describe('shouldRender', () => {
    const commit = { sha: 'abc' };
    const identicalSha = [{ commit }, { commit }];

    it.each`
      data            | index | result
      ${identicalSha} | ${0}  | ${true}
      ${identicalSha} | ${1}  | ${false}
    `('returns $result', ({ data, index, result }) => {
      expect(shouldRender(data, index)).toBe(result);
    });
  });

  describe('toggleBlameLineBorders', () => {
    it('adds classes', () => {
      toggleBlameLineBorders(BLAME_DATA_MOCK, true);
      expect(findContent()).toMatchSnapshot();
    });

    it('removes classes', () => {
      toggleBlameLineBorders(BLAME_DATA_MOCK, false);
      expect(findContent()).toMatchSnapshot();
    });
  });

  describe('hasBlameDataForChunk', () => {
    const chunk = { startingFrom: 0, totalLines: 70 };

    it.each([
      [[{ lineno: 1 }], true, 'within range'],
      [[{ lineno: 70 }], true, 'at boundary'],
      [[{ lineno: 71 }], false, 'outside range'],
      [[], false, 'empty'],
    ])('returns %s when blame data is %s', (blameData, expected) => {
      expect(hasBlameDataForChunk(blameData, chunk)).toBe(expected);
    });

    it('handles chunk with non-zero startingFrom', () => {
      const chunk2 = { startingFrom: 70, totalLines: 40 };
      expect(hasBlameDataForChunk([{ lineno: 80 }], chunk2)).toBe(true);
    });
  });
});
