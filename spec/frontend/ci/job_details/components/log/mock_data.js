export const mockJobLog = [
  {
    offset: 1000,
    content: [{ text: 'Running with gitlab-runner 12.1.0 (de7731dd)' }],
  },
  {
    offset: 1001,
    content: [{ text: ' on docker-auto-scale-com 8a6210b8' }],
  },
  {
    offset: 1002,
    content: [
      {
        text: 'Using Docker executor with image dev.gitlab.org3',
      },
    ],
    section: 'prepare-executor',
    section_header: true,
  },
  {
    offset: 1003,
    content: [{ text: 'Docker executor with image registry.gitlab.com ...' }],
    section: 'prepare-executor',
  },
  {
    offset: 1004,
    content: [{ text: 'Starting service ...', style: 'term-fg-l-green' }],
    section: 'prepare-executor',
  },
  {
    offset: 1005,
    content: [],
    section: 'prepare-executor',
    section_duration: '00:09',
  },
  {
    offset: 1006,
    content: [
      {
        text: 'Getting source from Git repository',
      },
    ],
    section: 'get-sources',
    section_header: true,
  },
  {
    offset: 1007,
    content: [{ text: 'Fetching changes with git depth set to 20...' }],
    section: 'get-sources',
  },
  {
    offset: 1008,
    content: [{ text: 'Initialized empty Git repository', style: 'term-fg-l-green' }],
    section: 'get-sources',
  },
  {
    offset: 1009,
    content: [],
    section: 'get-sources',
    section_duration: '00:19',
  },
];

export const mockJobLogLineCount = 8; // `text` entries in mockJobLog

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
