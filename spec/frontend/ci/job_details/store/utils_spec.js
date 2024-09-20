import { logLinesParser } from '~/ci/job_details/store/utils';

import {
  mockJobLines,
  mockJobLogWithTimestamp,
  mockEmptySection,
  mockContentSection,
  mockContentSectionClosed,
  mockContentSectionHiddenDuration,
  mockContentSubsection,
  mockTruncatedBottomSection,
  mockTruncatedTopSection,
} from '../components/log/mock_data';

describe('Jobs Store Utils', () => {
  describe('logLinesParser', () => {
    it('parses plain lines', () => {
      const result = logLinesParser(mockJobLines);

      expect(result).toEqual({
        lines: [
          {
            offset: 0,
            content: [
              {
                text: 'Running with gitlab-runner 12.1.0 (de7731dd)',
                style: 'term-fg-l-cyan term-bold',
              },
            ],
            lineNumber: 1,
          },
          {
            offset: 1001,
            content: [{ text: ' on docker-auto-scale-com 8a6210b8' }],
            lineNumber: 2,
          },
        ],
        sections: {},
      });
    });

    it('parses lines with timestamp', () => {
      const result = logLinesParser(mockJobLogWithTimestamp);

      expect(result).toEqual({
        lines: [
          {
            content: [
              {
                style: 'term-fg-l-cyan term-bold',
                text: 'Running with gitlab-runner 12.1.0 (de7731dd)',
              },
            ],
            lineNumber: 1,
            offset: 0,
            time: '12:43:46',
          },
          {
            content: [{ text: ' on docker-auto-scale-com 8a6210b8' }],
            lineNumber: 2,
            offset: 1001,
            time: 'ANOTHER_TIMESTAMP_FORMAT',
          },
        ],
        sections: {},
      });
    });

    it('parses an empty section', () => {
      const result = logLinesParser(mockEmptySection);

      expect(result).toEqual({
        lines: [
          {
            offset: 1002,
            content: [
              {
                text: 'Resolving secrets',
                style: 'term-fg-l-cyan term-bold',
              },
            ],
            lineNumber: 1,
            section: 'resolve-secrets',
            isHeader: true,
          },
        ],
        sections: {
          'resolve-secrets': {
            startLineNumber: 1,
            endLineNumber: 1,
            duration: '00:00',
            isClosed: false,
          },
        },
      });
    });

    it('parses a section with content', () => {
      const result = logLinesParser(mockContentSection);

      expect(result).toEqual({
        lines: [
          {
            content: [{ text: 'Using Docker executor with image dev.gitlab.org3' }],
            isHeader: true,
            lineNumber: 1,
            offset: 1004,
            section: 'prepare-executor',
          },
          {
            content: [{ text: 'Docker executor with image registry.gitlab.com ...' }],
            lineNumber: 2,
            offset: 1005,
            section: 'prepare-executor',
          },
          {
            content: [{ style: 'term-fg-l-green', text: 'Starting service ...' }],
            lineNumber: 3,
            offset: 1006,
            section: 'prepare-executor',
          },
        ],
        sections: {
          'prepare-executor': {
            startLineNumber: 1,
            endLineNumber: 3,
            duration: '00:09',
            isClosed: false,
          },
        },
      });
    });

    it('parses a closed section with content', () => {
      const result = logLinesParser(mockContentSectionClosed);

      expect(result.sections['mock-closed-section']).toMatchObject({
        isClosed: true,
      });
    });

    it('parses a closed section as open when hash is present', () => {
      const result = logLinesParser(mockContentSectionClosed, {}, '#L1');

      expect(result.sections['mock-closed-section']).toMatchObject({
        isClosed: false,
      });
    });

    it('parses a section with a hidden duration', () => {
      const result = logLinesParser(mockContentSectionHiddenDuration);

      expect(result.sections['mock-hidden-duration-section']).toMatchObject({
        hideDuration: true,
        duration: '00:09',
      });
    });

    it('parses a section with a sub section', () => {
      const result = logLinesParser(mockContentSubsection);

      expect(result).toEqual({
        lines: [
          {
            offset: 0,
            content: [{ text: 'Line 1' }],
            lineNumber: 1,
            section: 'mock-section',
            isHeader: true,
          },
          {
            offset: 1002,
            content: [{ text: 'Line 2 - section content' }],
            lineNumber: 2,
            section: 'mock-section',
          },
          {
            offset: 1003,
            content: [{ text: 'Line 3 - sub section header' }],
            lineNumber: 3,
            section: 'sub-section',
            isHeader: true,
          },
          {
            offset: 1004,
            content: [{ text: 'Line 4 - sub section content' }],
            lineNumber: 4,
            section: 'sub-section',
          },
          {
            offset: 1005,
            content: [{ text: 'Line 5 - sub sub section header with no content' }],
            lineNumber: 5,
            section: 'sub-sub-section',
            isHeader: true,
          },
          {
            offset: 1007,
            content: [{ text: 'Line 6 - sub section content 2' }],
            lineNumber: 6,
            section: 'sub-section',
          },
          {
            offset: 1009,
            content: [{ text: 'Line 7 - section content' }],
            lineNumber: 7,
            section: 'mock-section',
          },
          {
            offset: 1011,
            content: [{ text: 'Job succeeded' }],
            lineNumber: 8,
          },
        ],
        sections: {
          'mock-section': {
            startLineNumber: 1,
            endLineNumber: 7,
            duration: '00:59',
            isClosed: false,
          },
          'sub-section': {
            startLineNumber: 3,
            endLineNumber: 6,
            duration: '00:29',
            isClosed: false,
          },
          'sub-sub-section': {
            startLineNumber: 5,
            endLineNumber: 5,
            duration: '00:00',
            isClosed: false,
          },
        },
      });
    });

    it('parsing repeated lines returns the same result', () => {
      const result1 = logLinesParser(mockJobLines);
      const result2 = logLinesParser(mockJobLines, {
        currentLines: result1.lines,
        currentSections: result1.sections,
      });

      // `toBe` is used to ensure objects do not change and trigger Vue reactivity
      expect(result1.lines).toBe(result2.lines);
      expect(result1.sections).toBe(result2.sections);
    });

    it('discards repeated lines and adds new ones', () => {
      const result1 = logLinesParser(mockContentSection);
      const result2 = logLinesParser(
        [
          ...mockContentSection,
          {
            content: [{ text: 'offset is too low, is ignored' }],
            offset: 500,
          },
          {
            content: [{ text: 'one new line' }],
            offset: 1007,
          },
        ],
        {
          currentLines: result1.lines,
          currentSections: result1.sections,
        },
      );

      expect(result2).toEqual({
        lines: [
          {
            content: [{ text: 'Using Docker executor with image dev.gitlab.org3' }],
            isHeader: true,
            lineNumber: 1,
            offset: 1004,
            section: 'prepare-executor',
          },
          {
            content: [{ text: 'Docker executor with image registry.gitlab.com ...' }],
            lineNumber: 2,
            offset: 1005,
            section: 'prepare-executor',
          },
          {
            content: [{ style: 'term-fg-l-green', text: 'Starting service ...' }],
            lineNumber: 3,
            offset: 1006,
            section: 'prepare-executor',
          },
          {
            content: [{ text: 'one new line' }],
            lineNumber: 4,
            offset: 1007,
          },
        ],
        sections: {
          'prepare-executor': {
            startLineNumber: 1,
            endLineNumber: 3,
            duration: '00:09',
            isClosed: false,
          },
        },
      });
    });

    it('parses an interrupted job', () => {
      const result = logLinesParser(mockTruncatedBottomSection);

      expect(result.sections).toEqual({
        'mock-section': {
          startLineNumber: 1,
          endLineNumber: Infinity,
          duration: null,
          isClosed: false,
        },
      });
    });

    it('parses the ending of an incomplete section', () => {
      const result = logLinesParser(mockTruncatedTopSection);

      expect(result.sections).toEqual({
        'mock-section': {
          startLineNumber: 0,
          endLineNumber: 2,
          duration: '00:59',
          isClosed: false,
        },
      });
    });
  });
});
