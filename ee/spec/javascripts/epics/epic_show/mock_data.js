export const mockLabels = [
  {
    id: 26,
    title: 'Foo Label',
    description: 'Foobar',
    color: '#BADA55',
    text_color: '#FFFFFF',
  },
];

export const mockParticipants = [
  {
    id: 1,
    name: 'Administrator',
    username: 'root',
    state: 'active',
    avatar_url: '',
    web_url: 'http://127.0.0.1:3001/root',
  },
  {
    id: 12,
    name: 'Susy Johnson',
    username: 'tana_harvey',
    state: 'active',
    avatar_url: '',
    web_url: 'http://127.0.0.1:3001/tana_harvey',
  },
];

export const contentProps = {
  epicId: 1,
  endpoint: '',
  toggleSubscriptionPath: gl.TEST_HOST,
  updateEndpoint: gl.TEST_HOST,
  todoPath: gl.TEST_HOST,
  todoDeletePath: gl.TEST_HOST,
  canAdmin: true,
  canUpdate: true,
  canDestroy: true,
  markdownPreviewPath: '',
  markdownDocsPath: '',
  issueLinksEndpoint: '/',
  groupPath: '',
  namespace: 'gitlab-org',
  labelsPath: '',
  labelsWebUrl: '',
  epicsWebUrl: '',
  initialTitleHtml: '',
  initialTitleText: '',
  startDate: '2017-01-01',
  endDate: '2017-10-10',
  dueDate: '2017-10-10',
  startDateFixed: '2017-01-01',
  startDateIsFixed: true,
  startDateFromMilestones: '',
  dueDateFixed: '2017-10-10',
  dueDateIsFixed: true,
  dueDateFromMilestones: '',
  startDateSourcingMilestoneTitle: 'Milestone for Start Date',
  dueDateSourcingMilestoneTitle: 'Milestone for End Date',
  labels: mockLabels,
  participants: mockParticipants,
  subscribed: true,
  todoExists: false,
};

export const headerProps = {
  author: {
    url: `${gl.TEST_HOST}/url`,
    src: `${gl.TEST_HOST}/image`,
    username: '@root',
    name: 'Administrator',
  },
  created: (new Date()).toISOString(),
};

export const mockDatePickerProps = {
  blockClass: 'epic-date',
  collapsed: false,
  showToggleSidebar: false,
  isLoading: false,
  editable: true,
  label: 'Date',
  datePickerLabel: 'Fixed date',
  selectedDate: null,
  selectedDateIsFixed: true,
  dateFromMilestones: null,
  dateFixed: null,
  dateFromMilestonesTooltip: 'Select an issue with milestone to set date',
  isDateInvalid: false,
  dateInvalidTooltip: 'Selected date is invalid',
};

export const props = Object.assign({}, contentProps, headerProps);
