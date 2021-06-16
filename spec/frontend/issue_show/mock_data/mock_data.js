import { TEST_HOST } from 'helpers/test_constants';

export const initialRequest = {
  title: '<p>this is a title</p>',
  title_text: 'this is a title',
  description: '<p>this is a description!</p>',
  description_text: 'this is a description',
  task_status: '2 of 4 completed',
  updated_at: '2015-05-15T12:31:04.428Z',
  updated_by_name: 'Some User',
  updated_by_path: '/some_user',
  lock_version: 1,
};

export const secondRequest = {
  title: '<p>2</p>',
  title_text: '2',
  description: '<p>42</p>',
  description_text: '42',
  task_status: '0 of 0 completed',
  updated_at: '2016-05-15T12:31:04.428Z',
  updated_by_name: 'Other User',
  updated_by_path: '/other_user',
  lock_version: 2,
};

export const descriptionProps = {
  canUpdate: true,
  descriptionHtml: 'test',
  descriptionText: 'test',
  taskStatus: '',
  updateUrl: TEST_HOST,
};

export const publishedIncidentUrl = 'https://status.com/';

export const zoomMeetingUrl = 'https://gitlab.zoom.us/j/95919234811';

export const appProps = {
  canUpdate: true,
  canDestroy: true,
  endpoint: '/gitlab-org/gitlab-shell/-/issues/9/realtime_changes',
  updateEndpoint: TEST_HOST,
  issuableRef: '#1',
  issuableStatus: 'opened',
  initialTitleHtml: '',
  initialTitleText: '',
  initialDescriptionHtml: 'test',
  initialDescriptionText: 'test',
  lockVersion: 1,
  issueType: 'issue',
  markdownPreviewPath: '/',
  markdownDocsPath: '/',
  projectNamespace: '/',
  projectPath: '/',
  projectId: 1,
  issuableTemplateNamesPath: '/issuable-templates-path',
  zoomMeetingUrl,
  publishedIncidentUrl,
};
