import { logLinesParser, updateIncrementalTrace } from '~/jobs/store/utils';

describe('Jobs Store Utils', () => {
  describe('logLinesParser', () => {
    const mockData = [
      {
        offset: 1001,
        content: [{ text: ' on docker-auto-scale-com 8a6210b8' }],
      },
      {
        offset: 1002,
        content: [
          {
            text:
              'Using Docker executor with image dev.gitlab.org:5005/gitlab/gitlab-build-images:ruby-2.6.3-golang-1.11-git-2.22-chrome-73.0-node-12.x-yarn-1.16-postgresql-9.6-graphicsmagick-1.3.33',
          },
        ],
        sections: ['prepare-executor'],
        section_header: true,
      },
      {
        offset: 1003,
        content: [{ text: 'Starting service postgres:9.6.14 ...' }],
        sections: ['prepare-executor'],
      },
      {
        offset: 1004,
        content: [{ text: 'Pulling docker image postgres:9.6.14 ...', style: 'term-fg-l-green' }],
        sections: ['prepare-executor'],
      },
    ];

    let result;

    beforeEach(() => {
      result = logLinesParser(mockData);
    });

    describe('regular line', () => {
      it('adds a lineNumber property with correct index', () => {
        expect(result[0].lineNumber).toEqual(0);
        expect(result[1].line.lineNumber).toEqual(1);
      });
    });

    describe('collpasible section', () => {
      it('adds a `isClosed` property', () => {
        expect(result[1].isClosed).toEqual(true);
      });

      it('adds a `isHeader` property', () => {
        expect(result[1].isHeader).toEqual(true);
      });

      it('creates a lines array property with the content of the collpasible section', () => {
        expect(result[1].lines.length).toEqual(2);
        expect(result[1].lines[0].content).toEqual(mockData[2].content);
        expect(result[1].lines[1].content).toEqual(mockData[3].content);
      });
    });
  });

  describe('updateIncrementalTrace', () => {
    const originalTrace = [
      {
        offset: 1,
        content: [
          {
            text: 'Downloading',
          },
        ],
      },
    ];

    describe('without repeated section', () => {
      it('concats and parses both arrays', () => {
        const oldLog = logLinesParser(originalTrace);
        const newLog = [
          {
            offset: 2,
            content: [
              {
                text: 'log line',
              },
            ],
          },
        ];
        const result = updateIncrementalTrace(originalTrace, oldLog, newLog);

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
        const oldLog = logLinesParser(originalTrace);
        const newLog = [
          {
            offset: 1,
            content: [
              {
                text: 'log line',
              },
            ],
          },
        ];
        const result = updateIncrementalTrace(originalTrace, oldLog, newLog);

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
        const headerTrace = [
          {
            offset: 1,
            section_header: true,
            content: [
              {
                text: 'log line',
              },
            ],
            sections: ['section'],
          },
        ];
        const oldLog = logLinesParser(headerTrace);
        const newLog = [
          {
            offset: 1,
            section_header: true,
            content: [
              {
                text: 'updated log line',
              },
            ],
            sections: ['section'],
          },
        ];
        const result = updateIncrementalTrace(headerTrace, oldLog, newLog);

        expect(result).toEqual([
          {
            isClosed: true,
            isHeader: true,
            line: {
              offset: 1,
              section_header: true,
              content: [
                {
                  text: 'updated log line',
                },
              ],
              sections: ['section'],
              lineNumber: 0,
            },
            lines: [],
          },
        ]);
      });
    });

    describe('with collapsible line repeated', () => {
      it('updates the collapsible line and formats with the incremental part', () => {
        const collapsibleTrace = [
          {
            offset: 1,
            section_header: true,
            content: [
              {
                text: 'log line',
              },
            ],
            sections: ['section'],
          },
          {
            offset: 2,
            content: [
              {
                text: 'log line',
              },
            ],
            sections: ['section'],
          },
        ];
        const oldLog = logLinesParser(collapsibleTrace);
        const newLog = [
          {
            offset: 2,
            content: [
              {
                text: 'updated log line',
              },
            ],
            sections: ['section'],
          },
        ];
        const result = updateIncrementalTrace(collapsibleTrace, oldLog, newLog);

        expect(result).toEqual([
          {
            isClosed: true,
            isHeader: true,
            line: {
              offset: 1,
              section_header: true,
              content: [
                {
                  text: 'log line',
                },
              ],
              sections: ['section'],
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
                sections: ['section'],
                lineNumber: 1,
              },
            ],
          },
        ]);
      });
    });
  });
});
