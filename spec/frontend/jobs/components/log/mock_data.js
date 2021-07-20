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
    section: 'prepare-executor',
    section_header: true,
  },
  {
    offset: 1003,
    content: [{ text: 'Starting service postgres:9.6.14 ...', style: 'text-green' }],
    section: 'prepare-executor',
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
          'Using Docker executor with image dev.gitlab.org:5005/gitlab/gitlab-build-images:ruby-2.6.6-golang-1.14-git-2.28-lfs-2.9-chrome-84-node-12.x-yarn-1.21-postgresql-11-graphicsmagick-1.3.34',
      },
    ],
    section: 'prepare-executor',
    section_header: true,
  },
  {
    offset: 1003,
    content: [{ text: 'Starting service postgres:9.6.14 ...' }],
    section: 'prepare-executor',
  },
  {
    offset: 1004,
    content: [{ text: 'Pulling docker image postgres:9.6.14 ...', style: 'term-fg-l-green' }],
    section: 'prepare-executor',
  },
  {
    offset: 1005,
    content: [],
    section: 'prepare-executor',
    section_duration: '10:00',
  },
];

export const multipleCollapsibleSectionsMockData = [
  {
    offset: 1001,
    content: [{ text: ' on docker-auto-scale-com 8a6210b8' }],
  },
  {
    offset: 1002,
    content: [
      {
        text: 'Executing "step_script" stage of the job script',
      },
    ],
    section: 'step-script',
    section_header: true,
  },
  {
    offset: 1003,
    content: [{ text: 'sleep 60' }],
    section: 'step-script',
  },
  {
    offset: 1004,
    content: [
      {
        text:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam lorem dolor, congue ac condimentum vitae',
      },
    ],
    section: 'step-script',
  },
  {
    offset: 1005,
    content: [{ text: 'executing...' }],
    section: 'step-script',
  },
  {
    offset: 1006,
    content: [{ text: '1st collapsible section' }],
    section: 'collapsible-1',
    section_header: true,
  },
  {
    offset: 1007,
    content: [
      {
        text:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam lorem dolor, congue ac condimentum vitae',
      },
    ],
    section: 'collapsible-1',
  },
  {
    offset: 1008,
    content: [],
    section: 'collapsible-1',
    section_duration: '01:00',
  },
  {
    offset: 1009,
    content: [],
    section: 'step-script',
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
      lineNumber: 3,
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
      lineNumber: 3,
    },
  ],
};
