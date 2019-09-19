export const jobLog = [
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
    sections: ['prepare-executor'],
    section_header: true,
  },
  {
    offset: 1003,
    content: [{ text: 'Starting service postgres:9.6.14 ...', style: 'text-green' }],
    sections: ['prepare-executor'],
  },
];

export const utilsMockData = [
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
  {
    offset: 1005,
    content: [],
    sections: ['prepare-executor'],
    section_duration: '10:00',
  },
];

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
    sections: ['section'],
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
    sections: ['section'],
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

export const collapsibleTraceIncremental = [
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

export const nestedSectionClosed = {
  offset: 5,
  section_header: true,
  isHeader: true,
  isClosed: true,
  line: {
    content: [{ text: 'foo' }],
    sections: ['prepare-script'],
    lineNumber: 1,
  },
  section_duration: '00:03',
  lines: [
    {
      section_header: true,
      section_duration: '00:02',
      isHeader: true,
      isClosed: true,
      line: {
        offset: 52,
        content: [{ text: 'bar' }],
        sections: ['prepare-script', 'prepare-script-nested'],
        lineNumber: 2,
      },
      lines: [
        {
          offset: 80,
          content: [{ text: 'this is a collapsible nested section' }],
          sections: ['prepare-script', 'prepare-script-nested'],
          lineNumber: 3,
        },
      ],
    },
  ],
};

export const nestedSectionOpened = {
  offset: 5,
  section_header: true,
  isHeader: true,
  isClosed: false,
  line: {
    content: [{ text: 'foo' }],
    sections: ['prepare-script'],
    lineNumber: 1,
  },
  section_duration: '00:03',
  lines: [
    {
      section_header: true,
      section_duration: '00:02',
      isHeader: true,
      isClosed: false,
      line: {
        offset: 52,
        content: [{ text: 'bar' }],
        sections: ['prepare-script', 'prepare-script-nested'],
        lineNumber: 2,
      },
      lines: [
        {
          offset: 80,
          content: [{ text: 'this is a collapsible nested section' }],
          sections: ['prepare-script', 'prepare-script-nested'],
          lineNumber: 3,
        },
      ],
    },
  ],
};
