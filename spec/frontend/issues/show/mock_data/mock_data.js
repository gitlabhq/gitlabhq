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

export const descriptionHtmlWithList = `
  <ul data-sourcepos="1:1-3:8" dir="auto">
    <li data-sourcepos="1:1-1:8">todo 1</li>
    <li data-sourcepos="2:1-2:8">todo 2</li>
    <li data-sourcepos="3:1-3:8">todo 3</li>
  </ul>
`;

export const descriptionHtmlWithCheckboxes = `
  <ul dir="auto" class="task-list" data-sourcepos"3:1-5:12">
    <li class="task-list-item" data-sourcepos="3:1-3:11">
      <input class="task-list-item-checkbox" type="checkbox"> todo 1
    </li>
    <li class="task-list-item" data-sourcepos="4:1-4:12">
      <input class="task-list-item-checkbox" type="checkbox"> todo 2
    </li>
    <li class="task-list-item" data-sourcepos="5:1-5:12">
      <input class="task-list-item-checkbox" type="checkbox"> todo 3
    </li>
  </ul>
`;

export const descriptionHtmlWithTask = `
  <ul data-sourcepos="1:1-3:7" class="task-list" dir="auto">
    <li data-sourcepos="1:1-1:10" class="task-list-item">
      <input type="checkbox" class="task-list-item-checkbox" disabled>
      <a href="/gitlab-org/gitlab-test/-/issues/48" data-original="#48+" data-link="false" data-link-reference="false" data-project="1" data-issue="2" data-reference-format="+" data-reference-type="task" data-container="body" data-placement="top" title="1" class="gfm gfm-issue has-tooltip" data-issue-type="task">1 (#48)</a>
    </li>
    <li data-sourcepos="2:1-2:7" class="task-list-item">
      <input type="checkbox" class="task-list-item-checkbox" disabled> 2
    </li>
    <li data-sourcepos="3:1-3:7" class="task-list-item">
      <input type="checkbox" class="task-list-item-checkbox" disabled> 3
    </li>
  </ul>
`;

export const descriptionHtmlWithIssue = `
  <ul data-sourcepos="1:1-3:7" class="task-list" dir="auto">
    <li data-sourcepos="1:1-1:10" class="task-list-item">
      <input type="checkbox" class="task-list-item-checkbox" disabled>
      <a href="/gitlab-org/gitlab-test/-/issues/48" data-original="#48+" data-link="false" data-link-reference="false" data-project="1" data-issue="2" data-reference-format="+" data-reference-type="task" data-container="body" data-placement="top" title="1" class="gfm gfm-issue has-tooltip" data-issue-type="issue">1 (#48)</a>
    </li>
    <li data-sourcepos="2:1-2:7" class="task-list-item">
      <input type="checkbox" class="task-list-item-checkbox" disabled> 2
    </li>
    <li data-sourcepos="3:1-3:7" class="task-list-item">
      <input type="checkbox" class="task-list-item-checkbox" disabled> 3
    </li>
  </ul>
`;
