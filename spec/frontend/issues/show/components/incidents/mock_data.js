export const mockTimelineEventTags = {
  nodes: [
    {
      id: 'gid://gitlab/IncidentManagement::TimelineEvent/132',
      name: 'Start time',
    },
    {
      id: 'gid://gitlab/IncidentManagement::TimelineEvent/132',
      name: 'End time',
    },
  ],
};

export const mockEvents = [
  {
    action: 'comment',
    author: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      name: 'Administrator',
      username: 'root',
    },
    createdAt: '2022-03-22T15:59:08Z',
    id: 'gid://gitlab/IncidentManagement::TimelineEvent/132',
    note: 'Dummy event 1',
    noteHtml: '<p>Dummy event 1</p>',
    occurredAt: '2022-03-22T15:59:00Z',
    updatedAt: '2022-03-22T15:59:08Z',
    timelineEventTags: {
      nodes: [],
    },
    __typename: 'TimelineEventType',
  },
  {
    action: 'comment',
    author: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      name: 'Administrator',
      username: 'root',
    },
    createdAt: '2022-03-23T14:57:08Z',
    id: 'gid://gitlab/IncidentManagement::TimelineEvent/131',
    note: 'Dummy event 2',
    noteHtml: '<p>Dummy event 2</p>',
    occurredAt: '2022-03-23T14:57:00Z',
    updatedAt: '2022-03-23T14:57:08Z',
    timelineEventTags: mockTimelineEventTags,
    __typename: 'TimelineEventType',
  },
  {
    action: 'comment',
    author: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      name: 'Administrator',
      username: 'root',
    },
    createdAt: '2022-03-23T15:59:08Z',
    id: 'gid://gitlab/IncidentManagement::TimelineEvent/132',
    note: 'Dummy event 3',
    noteHtml: '<p>Dummy event 3</p>',
    occurredAt: '2022-03-23T15:59:00Z',
    updatedAt: '2022-03-23T15:59:08Z',
    timelineEventTags: {
      nodes: [],
    },
    __typename: 'TimelineEventType',
  },
];

const mockUpdatedEvent = {
  id: 'gid://gitlab/IncidentManagement::TimelineEvent/8',
  note: 'another one23',
  noteHtml: '<p>another one23</p>',
  action: 'comment',
  occurredAt: '2022-07-01T12:47:00Z',
  createdAt: '2022-07-20T12:47:40Z',
  timelineEventTags: [],
};

export const timelineEventsQueryListResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/8',
      incidentManagementTimelineEvents: {
        nodes: mockEvents,
      },
    },
  },
};

export const timelineEventsQueryEmptyResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/8',
      incidentManagementTimelineEvents: {
        nodes: [],
      },
    },
  },
};

export const timelineEventsCreateEventResponse = {
  data: {
    timelineEventCreate: {
      timelineEvent: {
        ...mockEvents[0],
      },
      errors: [],
    },
  },
};

export const timelineEventsCreateEventError = {
  data: {
    timelineEventCreate: {
      timelineEvent: {
        ...mockEvents[0],
      },
      errors: ['Create error'],
    },
  },
};

export const timelineEventsEditEventResponse = {
  data: {
    timelineEventUpdate: {
      timelineEvent: {
        ...mockUpdatedEvent,
      },
      errors: [],
      __typename: 'TimelineEventUpdatePayload',
    },
  },
};

export const timelineEventsEditEventError = {
  data: {
    timelineEventUpdate: {
      timelineEvent: {
        ...mockUpdatedEvent,
      },
      errors: ['Create error'],
    },
  },
};

const timelineEventDeleteData = (errors = []) => {
  return {
    data: {
      timelineEventDestroy: {
        timelineEvent: { ...mockEvents[0] },
        errors,
      },
    },
  };
};

export const timelineEventsDeleteEventResponse = timelineEventDeleteData();

export const timelineEventsDeleteEventError = timelineEventDeleteData(['Item does not exist']);

export const mockGetTimelineData = {
  project: {
    id: 'gid://gitlab/Project/19',
    incidentManagementTimelineEvents: {
      nodes: [
        {
          id: 'gid://gitlab/IncidentManagement::TimelineEvent/8',
          note: 'another one2',
          noteHtml: '<p>another one2</p>',
          action: 'comment',
          occurredAt: '2022-07-01T12:47:00Z',
          createdAt: '2022-07-20T12:47:40Z',
          timelineEventTags: {
            nodes: [],
          },
        },
      ],
    },
  },
};

export const fakeDate = '2020-07-08T00:00:00.000Z';

export const mockInputData = {
  note: 'test',
  occurredAt: '2020-08-10T02:30:00.000Z',
};

const { id, note, occurredAt, timelineEventTags } = mockEvents[0];
export const fakeEventData = { id, note, occurredAt, timelineEventTags };
export const fakeEventSaveData = {
  id,
  note,
  occurredAt,
  timelineEventTagNames: timelineEventTags,
  ...mockInputData,
};
