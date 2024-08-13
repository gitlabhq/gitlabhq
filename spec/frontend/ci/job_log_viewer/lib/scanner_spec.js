import Scanner from '~/ci/job_log_viewer/lib/scanner';

describe('Log scanner', () => {
  let scanner;

  beforeEach(() => {
    scanner = new Scanner();
  });

  it('scans a line', () => {
    expect(scanner.scan('line')).toEqual({
      content: [{ style: [], text: 'line' }],
      sections: [],
    });
  });

  it('scans a line with spacing', () => {
    expect(scanner.scan('  on runner')).toEqual({
      content: [{ style: [], text: '  on runner' }],
      sections: [],
    });
  });

  it('scans a line with a style', () => {
    expect(scanner.scan('\u001b[1;41mline 2\u001b[0;m')).toEqual({
      content: [
        {
          text: 'line 2',
          style: ['xterm-bg-1', 'term-bold'],
        },
      ],
      sections: [],
    });
  });

  it('scans a line with styles', () => {
    expect(scanner.scan('\u001b[32;1mline 1\u001b[0;m')).toEqual({
      content: [
        {
          text: 'line 1',
          style: ['term-fg-green', 'term-bold'],
        },
      ],
      sections: [],
    });
  });

  it('scans line that shows progress with CR char', () => {
    expect(scanner.scan('Progress 1...\rProgress 2...\rDone!')).toEqual({
      content: [
        {
          text: 'Done!',
          style: [],
        },
      ],
      sections: [],
    });
  });

  it('scans a section with timestamps', () => {
    const lines = [
      '2024-01-01T00:01:00.000000Z 00O section_start:1000:my_section[key1=value1,key2=value2]\r',
      '2024-01-01T00:02:00.000000Z 00O+header 1',
      '2024-01-01T00:03:00.000000Z 00O line 1',
      '2024-01-01T00:04:00.000000Z 00O line 2',
      '2024-01-01T00:05:00.000000Z 00O section_end:1010:my_section\r',
    ];

    expect(lines.map((l) => scanner.scan(l))).toEqual([
      {
        timestamp: '2024-01-01T00:01:00.000000Z',
        header: 'my_section',
        options: { key1: 'value1', key2: 'value2' },
        content: [],
        sections: [],
      },
      {
        append: true,
        timestamp: '2024-01-01T00:02:00.000000Z',
        content: [{ style: [], text: 'header 1' }],
      },
      {
        timestamp: '2024-01-01T00:03:00.000000Z',
        content: [{ style: [], text: 'line 1' }],
        sections: ['my_section'],
      },
      {
        timestamp: '2024-01-01T00:04:00.000000Z',
        content: [{ style: [], text: 'line 2' }],
        sections: ['my_section'],
      },
      null,
    ]);
  });

  it('scans two sections with timestamps', () => {
    const lines = [
      '2024-01-01T00:01:00.000000Z 00O section_start:1000:my_section[key1=value1,key2=value2]\r',
      '2024-01-01T00:02:00.000000Z 00O+header 1...',
      '2024-01-01T00:03:00.000000Z 00O+...continues',
      '2024-01-01T00:04:00.000000Z 00O line 1...',
      '2024-01-01T00:05:00.000000Z 00O+...also continues',
      '2024-01-01T00:06:00.000000Z 00O section_end:1010:my_section\r',
      '2024-01-01T00:07:00.000000Z 00O+section_start:1010:my_section_2\r',
      '2024-01-01T00:08:00.000000Z 00O+header 2',
      '2024-01-01T00:09:00.000000Z 00O line 2',
      '2024-01-01T00:10:00.000000Z 00O section_end:1020:my_section_2\r',
    ];

    expect(lines.map((l) => scanner.scan(l))).toEqual([
      {
        content: [],
        header: 'my_section',
        options: { key1: 'value1', key2: 'value2' },
        sections: [],
        timestamp: '2024-01-01T00:01:00.000000Z',
      },
      {
        append: true,
        content: [{ style: [], text: 'header 1...' }],
        timestamp: '2024-01-01T00:02:00.000000Z',
      },
      {
        append: true,
        content: [{ style: [], text: '...continues' }],
        timestamp: '2024-01-01T00:03:00.000000Z',
      },
      {
        content: [{ style: [], text: 'line 1...' }],
        sections: ['my_section'],
        timestamp: '2024-01-01T00:04:00.000000Z',
      },
      {
        append: true,
        content: [{ style: [], text: '...also continues' }],
        timestamp: '2024-01-01T00:05:00.000000Z',
      },
      null,
      {
        content: [],
        header: 'my_section_2',
        options: undefined,
        sections: [],
        timestamp: '2024-01-01T00:07:00.000000Z',
      },
      {
        append: true,
        content: [{ style: [], text: 'header 2' }],
        timestamp: '2024-01-01T00:08:00.000000Z',
      },
      {
        content: [{ style: [], text: 'line 2' }],
        sections: ['my_section_2'],
        timestamp: '2024-01-01T00:09:00.000000Z',
      },
      null,
    ]);
  });

  it('scans a section with its duration', () => {
    const lines = [
      'section_start:1000:my_section\rheader 1',
      'line 1',
      'line 2',
      'section_end:1010:my_section',
    ];

    expect(lines.map((l) => scanner.scan(l))).toEqual([
      {
        content: [{ style: [], text: 'header 1' }],
        header: 'my_section',
        sections: [],
      },
      { content: [{ style: [], text: 'line 1' }], sections: ['my_section'] },
      { content: [{ style: [], text: 'line 2' }], sections: ['my_section'] },
      null,
    ]);
  });

  it('scans a section with options', () => {
    const lines = [
      'section_start:1000:my_section[key1=value1,key2=value2]\rheader 1',
      'line 1',
      'section_end:1010:my_section',
    ];

    expect(lines.map((l) => scanner.scan(l))).toEqual([
      {
        content: [{ style: [], text: 'header 1' }],
        header: 'my_section',
        options: { key1: 'value1', key2: 'value2' },
        sections: [],
      },
      { content: [{ style: [], text: 'line 1' }], sections: ['my_section'] },
      null,
    ]);
  });

  it('scans a sub section with their durations', () => {
    const lines = [
      'section_start:1010:my_section\rheader 1',
      'line 1',
      'section_start:1020:my_sub_section\rheader 2',
      'line 2',
      'section_end:1030:my_sub_section',
      'line 3',
      'section_end:1040:my_section',
    ];

    expect(lines.map((l) => scanner.scan(l))).toEqual([
      {
        content: [{ style: [], text: 'header 1' }],
        header: 'my_section',
        sections: [],
      },
      { content: [{ style: [], text: 'line 1' }], sections: ['my_section'] },
      {
        content: [{ style: [], text: 'header 2' }],
        header: 'my_sub_section',
        sections: ['my_section'],
      },
      { content: [{ style: [], text: 'line 2' }], sections: ['my_section', 'my_sub_section'] },
      null,
      { content: [{ style: [], text: 'line 3' }], sections: ['my_section'] },
      null,
    ]);
  });

  describe('scans malformed sections as regular text', () => {
    it.each([
      'section_start:not_a_number:my_section',
      'section_start:100:',
      'section_wrong:100:my_section',
    ])('scans "%s"', (text) => {
      expect(scanner.scan(text)).toEqual({
        content: [{ style: [], text }],
        sections: [],
      });
    });
  });
});
