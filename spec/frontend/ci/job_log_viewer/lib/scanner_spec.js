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
          style: ['xterm-bg-9', 'term-bold'],
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
          style: ['xterm-fg-10', 'term-bold'],
        },
      ],
      sections: [],
    });
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
      { content: [{ duration: 10, section: 'my_section' }], sections: [] },
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
      { content: [{ duration: 10, section: 'my_section' }], sections: [] },
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
      { content: [{ duration: 10, section: 'my_sub_section' }], sections: ['my_section'] },
      { content: [{ style: [], text: 'line 3' }], sections: ['my_section'] },
      { content: [{ duration: 30, section: 'my_section' }], sections: [] },
    ]);
  });
});
