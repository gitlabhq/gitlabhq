import {
  logLinesParser,
  logLinesParserLegacy,
  updateIncrementalTrace,
  parseHeaderLine,
  parseLine,
  addDurationToHeader,
  isCollapsibleSection,
  findOffsetAndRemove,
  getIncrementalLineNumber,
} from '~/jobs/store/utils';
import {
  utilsMockData,
  originalTrace,
  regularIncremental,
  regularIncrementalRepeated,
  headerTrace,
  headerTraceIncremental,
  collapsibleTrace,
  collapsibleTraceIncremental,
  multipleCollapsibleSectionsMockData,
} from '../components/log/mock_data';

describe('Jobs Store Utils', () => {
  describe('parseHeaderLine', () => {
    it('returns a new object with the header keys and the provided line parsed', () => {
      const headerLine = { content: [{ text: 'foo' }] };
      const parsedHeaderLine = parseHeaderLine(headerLine, 2);

      expect(parsedHeaderLine).toEqual({
        isClosed: false,
        isHeader: true,
        line: {
          ...headerLine,
          lineNumber: 2,
        },
        lines: [],
      });
    });

    it('pre-closes a section when specified in options', () => {
      const headerLine = { content: [{ text: 'foo' }], section_options: { collapsed: 'true' } };

      const parsedHeaderLine = parseHeaderLine(headerLine, 2);

      expect(parsedHeaderLine.isClosed).toBe(true);
    });
  });

  describe('parseLine', () => {
    it('returns a new object with the lineNumber key added to the provided line object', () => {
      const line = { content: [{ text: 'foo' }] };
      const parsed = parseLine(line, 1);
      expect(parsed.content).toEqual(line.content);
      expect(parsed.lineNumber).toEqual(1);
    });
  });

  describe('addDurationToHeader', () => {
    const duration = {
      offset: 106,
      content: [],
      section: 'prepare-script',
      section_duration: '00:03',
    };

    it('adds the section duration to the correct header', () => {
      const parsed = [
        {
          isClosed: false,
          isHeader: true,
          line: {
            section: 'prepare-script',
            content: [{ text: 'foo' }],
          },
          lines: [],
        },
        {
          isClosed: false,
          isHeader: true,
          line: {
            section: 'foo-bar',
            content: [{ text: 'foo' }],
          },
          lines: [],
        },
      ];

      addDurationToHeader(parsed, duration);

      expect(parsed[0].line.section_duration).toEqual(duration.section_duration);
      expect(parsed[1].line.section_duration).toEqual(undefined);
    });

    it('does not add the section duration when the headers do not match', () => {
      const parsed = [
        {
          isClosed: false,
          isHeader: true,
          line: {
            section: 'bar-foo',
            content: [{ text: 'foo' }],
          },
          lines: [],
        },
        {
          isClosed: false,
          isHeader: true,
          line: {
            section: 'foo-bar',
            content: [{ text: 'foo' }],
          },
          lines: [],
        },
      ];
      addDurationToHeader(parsed, duration);

      expect(parsed[0].line.section_duration).toEqual(undefined);
      expect(parsed[1].line.section_duration).toEqual(undefined);
    });

    it('does not add when content has no headers', () => {
      const parsed = [
        {
          section: 'bar-foo',
          content: [{ text: 'foo' }],
          lineNumber: 1,
        },
        {
          section: 'foo-bar',
          content: [{ text: 'foo' }],
          lineNumber: 2,
        },
      ];

      addDurationToHeader(parsed, duration);

      expect(parsed[0].line).toEqual(undefined);
      expect(parsed[1].line).toEqual(undefined);
    });
  });

  describe('isCollapsibleSection', () => {
    const header = {
      isHeader: true,
      line: {
        section: 'foo',
      },
    };
    const line = {
      lineNumber: 1,
      section: 'foo',
      content: [],
    };

    it('returns true when line belongs to the last section', () => {
      expect(isCollapsibleSection([header], header, { section: 'foo', content: [] })).toEqual(true);
    });

    it('returns false when last line was not an header', () => {
      expect(isCollapsibleSection([line], line, { section: 'bar' })).toEqual(false);
    });

    it('returns false when accumulator is empty', () => {
      expect(isCollapsibleSection([], { isHeader: true }, { section: 'bar' })).toEqual(false);
    });

    it('returns false when section_duration is defined', () => {
      expect(isCollapsibleSection([header], header, { section_duration: '10:00' })).toEqual(false);
    });

    it('returns false when `section` is not a match', () => {
      expect(isCollapsibleSection([header], header, { section: 'bar' })).toEqual(false);
    });

    it('returns false when no parameters are provided', () => {
      expect(isCollapsibleSection()).toEqual(false);
    });
  });
  describe('logLinesParserLegacy', () => {
    let result;

    beforeEach(() => {
      result = logLinesParserLegacy(utilsMockData);
    });

    describe('regular line', () => {
      it('adds a lineNumber property with correct index', () => {
        expect(result[0].lineNumber).toEqual(0);
        expect(result[1].line.lineNumber).toEqual(1);
      });
    });

    describe('collapsible section', () => {
      it('adds a `isClosed` property', () => {
        expect(result[1].isClosed).toEqual(false);
      });

      it('adds a `isHeader` property', () => {
        expect(result[1].isHeader).toEqual(true);
      });

      it('creates a lines array property with the content of the collapsible section', () => {
        expect(result[1].lines.length).toEqual(2);
        expect(result[1].lines[0].content).toEqual(utilsMockData[2].content);
        expect(result[1].lines[1].content).toEqual(utilsMockData[3].content);
      });
    });

    describe('section duration', () => {
      it('adds the section information to the header section', () => {
        expect(result[1].line.section_duration).toEqual(utilsMockData[4].section_duration);
      });

      it('does not add section duration as a line', () => {
        expect(result[1].lines.includes(utilsMockData[4])).toEqual(false);
      });
    });
  });

  describe('logLinesParser', () => {
    let result;

    beforeEach(() => {
      result = logLinesParser(utilsMockData);
    });

    describe('regular line', () => {
      it('adds a lineNumber property with correct index', () => {
        expect(result.parsedLines[0].lineNumber).toEqual(1);
        expect(result.parsedLines[1].line.lineNumber).toEqual(2);
      });
    });

    describe('collapsible section', () => {
      it('adds a `isClosed` property', () => {
        expect(result.parsedLines[1].isClosed).toEqual(false);
      });

      it('adds a `isHeader` property', () => {
        expect(result.parsedLines[1].isHeader).toEqual(true);
      });

      it('creates a lines array property with the content of the collapsible section', () => {
        expect(result.parsedLines[1].lines.length).toEqual(2);
        expect(result.parsedLines[1].lines[0].content).toEqual(utilsMockData[2].content);
        expect(result.parsedLines[1].lines[1].content).toEqual(utilsMockData[3].content);
      });
    });

    describe('section duration', () => {
      it('adds the section information to the header section', () => {
        expect(result.parsedLines[1].line.section_duration).toEqual(
          utilsMockData[4].section_duration,
        );
      });

      it('does not add section duration as a line', () => {
        expect(result.parsedLines[1].lines.includes(utilsMockData[4])).toEqual(false);
      });
    });

    describe('multiple collapsible sections', () => {
      beforeEach(() => {
        result = logLinesParser(multipleCollapsibleSectionsMockData);
      });

      it('should contain a section inside another section', () => {
        const innerSection = [
          {
            isClosed: false,
            isHeader: true,
            line: {
              content: [{ text: '1st collapsible section' }],
              lineNumber: 6,
              offset: 1006,
              section: 'collapsible-1',
              section_duration: '01:00',
              section_header: true,
            },
            lines: [
              {
                content: [
                  {
                    text:
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam lorem dolor, congue ac condimentum vitae',
                  },
                ],
                lineNumber: 7,
                offset: 1007,
                section: 'collapsible-1',
              },
            ],
          },
        ];

        expect(result.parsedLines[1].lines).toEqual(expect.arrayContaining(innerSection));
      });
    });
  });

  describe('findOffsetAndRemove', () => {
    describe('when last item is header', () => {
      const existingLog = [
        {
          isHeader: true,
          isClosed: false,
          line: { content: [{ text: 'bar' }], offset: 10, lineNumber: 1 },
        },
      ];

      describe('and matches the offset', () => {
        it('returns an array with the item removed', () => {
          const newData = [{ offset: 10, content: [{ text: 'foobar' }] }];
          const result = findOffsetAndRemove(newData, existingLog);

          expect(result).toEqual([]);
        });
      });

      describe('and does not match the offset', () => {
        it('returns the provided existing log', () => {
          const newData = [{ offset: 110, content: [{ text: 'foobar' }] }];
          const result = findOffsetAndRemove(newData, existingLog);

          expect(result).toEqual(existingLog);
        });
      });
    });

    describe('when last item is a regular line', () => {
      const existingLog = [{ content: [{ text: 'bar' }], offset: 10, lineNumber: 1 }];

      describe('and matches the offset', () => {
        it('returns an array with the item removed', () => {
          const newData = [{ offset: 10, content: [{ text: 'foobar' }] }];
          const result = findOffsetAndRemove(newData, existingLog);

          expect(result).toEqual([]);
        });
      });

      describe('and does not match the fofset', () => {
        it('returns the provided old log', () => {
          const newData = [{ offset: 101, content: [{ text: 'foobar' }] }];
          const result = findOffsetAndRemove(newData, existingLog);

          expect(result).toEqual(existingLog);
        });
      });
    });

    describe('when last item is nested', () => {
      const existingLog = [
        {
          isHeader: true,
          isClosed: false,
          lines: [{ offset: 101, content: [{ text: 'foobar' }], lineNumber: 2 }],
          line: {
            offset: 10,
            lineNumber: 1,
            section_duration: '10:00',
          },
        },
      ];

      describe('and matches the offset', () => {
        it('returns an array with the last nested line item removed', () => {
          const newData = [{ offset: 101, content: [{ text: 'foobar' }] }];

          const result = findOffsetAndRemove(newData, existingLog);
          expect(result[0].lines).toEqual([]);
        });
      });

      describe('and does not match the offset', () => {
        it('returns the provided old log', () => {
          const newData = [{ offset: 120, content: [{ text: 'foobar' }] }];

          const result = findOffsetAndRemove(newData, existingLog);
          expect(result).toEqual(existingLog);
        });
      });
    });

    describe('when no data is provided', () => {
      it('returns an empty array', () => {
        const result = findOffsetAndRemove();
        expect(result).toEqual([]);
      });
    });
  });

  describe('getIncrementalLineNumber', () => {
    describe('when last line is 0', () => {
      it('returns 1', () => {
        const log = [
          {
            content: [],
            lineNumber: 0,
          },
        ];

        expect(getIncrementalLineNumber(log)).toEqual(1);
      });
    });

    describe('with unnested line', () => {
      it('returns the lineNumber of the last item in the array', () => {
        const log = [
          {
            content: [],
            lineNumber: 10,
          },
          {
            content: [],
            lineNumber: 101,
          },
        ];

        expect(getIncrementalLineNumber(log)).toEqual(102);
      });
    });

    describe('when last line is the header section', () => {
      it('returns the lineNumber of the last item in the array', () => {
        const log = [
          {
            content: [],
            lineNumber: 10,
          },
          {
            isHeader: true,
            line: {
              lineNumber: 101,
              content: [],
            },
            lines: [],
          },
        ];

        expect(getIncrementalLineNumber(log)).toEqual(102);
      });
    });

    describe('when last line is a nested line', () => {
      it('returns the lineNumber of the last item in the nested array', () => {
        const log = [
          {
            content: [],
            lineNumber: 10,
          },
          {
            isHeader: true,
            line: {
              lineNumber: 101,
              content: [],
            },
            lines: [
              {
                lineNumber: 102,
                content: [],
              },
              { lineNumber: 103, content: [] },
            ],
          },
        ];

        expect(getIncrementalLineNumber(log)).toEqual(104);
      });
    });
  });

  describe('updateIncrementalTrace', () => {
    describe('without repeated section', () => {
      it('concats and parses both arrays', () => {
        const oldLog = logLinesParserLegacy(originalTrace);
        const result = updateIncrementalTrace(regularIncremental, oldLog);

        expect(result).toEqual([
          {
            offset: 1,
            content: [
              {
                text: 'Downloading',
              },
            ],
            lineNumber: 0,
          },
          {
            offset: 2,
            content: [
              {
                text: 'log line',
              },
            ],
            lineNumber: 1,
          },
        ]);
      });
    });

    describe('with regular line repeated offset', () => {
      it('updates the last line and formats with the incremental part', () => {
        const oldLog = logLinesParserLegacy(originalTrace);
        const result = updateIncrementalTrace(regularIncrementalRepeated, oldLog);

        expect(result).toEqual([
          {
            offset: 1,
            content: [
              {
                text: 'log line',
              },
            ],
            lineNumber: 0,
          },
        ]);
      });
    });

    describe('with header line repeated', () => {
      it('updates the header line and formats with the incremental part', () => {
        const oldLog = logLinesParserLegacy(headerTrace);
        const result = updateIncrementalTrace(headerTraceIncremental, oldLog);

        expect(result).toEqual([
          {
            isClosed: false,
            isHeader: true,
            line: {
              offset: 1,
              section_header: true,
              content: [
                {
                  text: 'updated log line',
                },
              ],
              section: 'section',
              lineNumber: 0,
            },
            lines: [],
          },
        ]);
      });
    });

    describe('with collapsible line repeated', () => {
      it('updates the collapsible line and formats with the incremental part', () => {
        const oldLog = logLinesParserLegacy(collapsibleTrace);
        const result = updateIncrementalTrace(collapsibleTraceIncremental, oldLog);

        expect(result).toEqual([
          {
            isClosed: false,
            isHeader: true,
            line: {
              offset: 1,
              section_header: true,
              content: [
                {
                  text: 'log line',
                },
              ],
              section: 'section',
              lineNumber: 0,
            },
            lines: [
              {
                offset: 2,
                content: [
                  {
                    text: 'updated log line',
                  },
                ],
                section: 'section',
                lineNumber: 1,
              },
            ],
          },
        ]);
      });
    });
  });
});
