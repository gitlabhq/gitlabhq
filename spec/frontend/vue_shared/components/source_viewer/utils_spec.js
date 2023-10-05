import { setHTMLFixture } from 'helpers/fixtures';
import {
  calculateBlameOffset,
  toggleBlameClasses,
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

  describe('toggleBlameClasses', () => {
    it('adds classes', () => {
      toggleBlameClasses(BLAME_DATA_MOCK, true);
      expect(findContent()).toMatchSnapshot();
    });

    it('removes classes', () => {
      toggleBlameClasses(BLAME_DATA_MOCK, false);
      expect(findContent()).toMatchSnapshot();
    });
  });
});
