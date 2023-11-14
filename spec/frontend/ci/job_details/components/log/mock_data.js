export const mockJobLines = [
  {
    offset: 0,
    content: [
      {
        text: 'Running with gitlab-runner 12.1.0 (de7731dd)',
        style: 'term-fg-l-cyan term-bold',
      },
    ],
  },
  {
    offset: 1001,
    content: [{ text: ' on docker-auto-scale-com 8a6210b8' }],
  },
];

export const mockEmptySection = [
  {
    offset: 1002,
    content: [
      {
        text: 'Resolving secrets',
        style: 'term-fg-l-cyan term-bold',
      },
    ],
    section: 'resolve-secrets',
    section_header: true,
  },
  {
    offset: 1003,
    content: [],
    section: 'resolve-secrets',
    section_footer: true,
    section_duration: '00:00',
  },
];

export const mockContentSection = [
  {
    offset: 1004,
    content: [
      {
        text: 'Using Docker executor with image dev.gitlab.org3',
      },
    ],
    section: 'prepare-executor',
    section_header: true,
  },
  {
    offset: 1005,
    content: [{ text: 'Docker executor with image registry.gitlab.com ...' }],
    section: 'prepare-executor',
  },
  {
    offset: 1006,
    content: [{ text: 'Starting service ...', style: 'term-fg-l-green' }],
    section: 'prepare-executor',
  },
  {
    offset: 1007,
    content: [],
    section: 'prepare-executor',
    section_footer: true,
    section_duration: '00:09',
  },
];

export const mockJobLog = [...mockJobLines, ...mockEmptySection, ...mockContentSection];

export const mockJobLogLineCount = 6; // `text` entries in mockJobLog

export const originalTrace = [
  {
    offset: 1,
    content: [
      {
        text: 'Downloading',
      },
    ],
  },
];

export const regularIncremental = [
  {
    offset: 2,
    content: [
      {
        text: 'log line',
      },
    ],
  },
];

export const regularIncrementalRepeated = [
  {
    offset: 1,
    content: [
      {
        text: 'log line',
      },
    ],
  },
];

export const headerTrace = [
  {
    offset: 1,
    section_header: true,
    content: [
      {
        text: 'log line',
      },
    ],
    section: 'section',
  },
];

export const headerTraceIncremental = [
  {
    offset: 1,
    section_header: true,
    content: [
      {
        text: 'updated log line',
      },
    ],
    section: 'section',
  },
];

export const collapsibleTrace = [
  {
    offset: 1,
    section_header: true,
    content: [
      {
        text: 'log line',
      },
    ],
    section: 'section',
  },
  {
    offset: 2,
    content: [
      {
        text: 'log line',
      },
    ],
    section: 'section',
  },
];

export const collapsibleTraceIncremental = [
  {
    offset: 2,
    content: [
      {
        text: 'updated log line',
      },
    ],
    section: 'section',
  },
];

export const collapsibleSectionClosed = {
  offset: 5,
  section_header: true,
  isHeader: true,
  isClosed: true,
  line: {
    content: [{ text: 'foo' }],
    section: 'prepare-script',
    lineNumber: 1,
  },
  section_duration: '00:03',
  lines: [
    {
      offset: 80,
      content: [{ text: 'this is a collapsible nested section' }],
      section: 'prepare-script',
      lineNumber: 2,
    },
  ],
};

export const collapsibleSectionOpened = {
  offset: 5,
  section_header: true,
  isHeader: true,
  isClosed: false,
  line: {
    content: [{ text: 'foo' }],
    section: 'prepare-script',
    lineNumber: 1,
  },
  section_duration: '00:03',
  lines: [
    {
      offset: 80,
      content: [{ text: 'this is a collapsible nested section' }],
      section: 'prepare-script',
      lineNumber: 2,
    },
  ],
};
