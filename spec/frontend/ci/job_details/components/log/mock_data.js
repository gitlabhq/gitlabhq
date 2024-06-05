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

export const mockJobLogEnd = [
  {
    offset: 1008,
    content: [{ text: 'Job succeeded' }],
  },
];

export const mockJobLog = [
  ...mockJobLines,
  ...mockEmptySection,
  ...mockContentSection,
  ...mockJobLogEnd,
];

export const mockJobLogWithTimestamp = [
  {
    offset: 0,
    timestamp: '2024-05-22T12:43:46.962646Z',
    content: [
      {
        text: 'Running with gitlab-runner 12.1.0 (de7731dd)',
        style: 'term-fg-l-cyan term-bold',
      },
    ],
  },
  {
    offset: 1001,
    timestamp: 'ANOTHER_TIMESTAMP_FORMAT',
    content: [{ text: ' on docker-auto-scale-com 8a6210b8' }],
  },
];

export const mockJobLogLineCount = 7; // `text` entries in mockJobLog

export const mockContentSectionClosed = [
  {
    offset: 0,
    content: [
      {
        text: 'Using Docker executor with image dev.gitlab.org3',
      },
    ],
    section: 'mock-closed-section',
    section_header: true,
    section_options: { collapsed: true },
  },
  {
    offset: 1003,
    content: [{ text: 'Docker executor with image registry.gitlab.com ...' }],
    section: 'mock-closed-section',
  },
  {
    offset: 1004,
    content: [{ text: 'Starting service ...', style: 'term-fg-l-green' }],
    section: 'mock-closed-section',
  },
  {
    offset: 1005,
    content: [],
    section: 'mock-closed-section',
    section_footer: true,
    section_duration: '00:09',
  },
];

export const mockContentSectionHiddenDuration = [
  {
    offset: 0,
    content: [{ text: 'Line 1' }],
    section: 'mock-hidden-duration-section',
    section_header: true,
    section_options: { hide_duration: 'true' },
  },
  {
    offset: 1001,
    content: [{ text: 'Line 2' }],
    section: 'mock-hidden-duration-section',
  },
  {
    offset: 1002,
    content: [],
    section: 'mock-hidden-duration-section',
    section_footer: true,
    section_duration: '00:09',
  },
];

export const mockContentSubsection = [
  {
    offset: 0,
    content: [{ text: 'Line 1' }],
    section: 'mock-section',
    section_header: true,
  },
  {
    offset: 1002,
    content: [{ text: 'Line 2 - section content' }],
    section: 'mock-section',
  },
  {
    offset: 1003,
    content: [{ text: 'Line 3 - sub section header' }],
    section: 'sub-section',
    section_header: true,
  },
  {
    offset: 1004,
    content: [{ text: 'Line 4 - sub section content' }],
    section: 'sub-section',
  },
  {
    offset: 1005,
    content: [{ text: 'Line 5 - sub sub section header with no content' }],
    section: 'sub-sub-section',
    section_header: true,
  },
  {
    offset: 1006,
    content: [],
    section: 'sub-sub-section',
    section_footer: true,
    section_duration: '00:00',
  },

  {
    offset: 1007,
    content: [{ text: 'Line 6 - sub section content 2' }],
    section: 'sub-section',
  },
  {
    offset: 1008,
    content: [],
    section: 'sub-section',
    section_footer: true,
    section_duration: '00:29',
  },
  {
    offset: 1009,
    content: [{ text: 'Line 7 - section content' }],
    section: 'mock-section',
  },
  {
    offset: 1010,
    content: [],
    section: 'mock-section',
    section_footer: true,
    section_duration: '00:59',
  },
  {
    offset: 1011,
    content: [{ text: 'Job succeeded' }],
  },
];

export const mockTruncatedBottomSection = [
  // only the top of a section is obtained, such as when a job gets cancelled
  {
    offset: 1004,
    content: [
      {
        text: 'Starting job',
      },
    ],
    section: 'mock-section',
    section_header: true,
  },
  {
    offset: 1005,
    content: [{ text: 'Job interrupted' }],
    section: 'mock-section',
  },
];

export const mockTruncatedTopSection = [
  // only the bottom half of a section is obtained, such as when jobs are cut off due to large sizes
  {
    offset: 1008,
    content: [{ text: 'Line N - incomplete section content' }],
    section: 'mock-section',
  },
  {
    offset: 1009,
    content: [{ text: 'Line N+1 - incomplete section content' }],
    section: 'mock-section',
  },
  {
    offset: 1010,
    content: [],
    section: 'mock-section',
    section_footer: true,
    section_duration: '00:59',
  },
  {
    offset: 1011,
    content: [{ text: 'Job succeeded' }],
  },
];
