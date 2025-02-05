// Copied to ee/spec/frontend/notes/mock_data.js
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

export const notesDataMock = {
  discussionsPath: '/gitlab-org/gitlab-foss/issues/26/discussions.json',
  lastFetchedAt: 1501862675,
  markdownDocsPath: '/help/user/markdown',
  newSessionPath: '/users/sign_in?redirect_to_referer=yes',
  notesPath: '/gitlab-org/gitlab-foss/noteable/issue/98/notes',
  draftsPath: '/flightjs/flight/-/merge_requests/4/drafts',
  quickActionsDocsPath: '/help/user/project/quick_actions',
  registerPath: '/users/sign_up?redirect_to_referer=yes',
  prerenderedNotesCount: 1,
  closePath: '/twitter/flight/issues/9.json?issue%5Bstate_event%5D=close',
  reopenPath: '/twitter/flight/issues/9.json?issue%5Bstate_event%5D=reopen',
  canAwardEmoji: true,
  noteableType: 'issue',
  noteableId: 1,
  projectId: 2,
  groupId: null,
};

export const userDataMock = {
  avatar_url: 'mock_path',
  id: 1,
  name: 'Root',
  path: '/root',
  state: 'active',
  username: 'root',
};

export const noteableDataMock = {
  assignees: [],
  author_id: 1,
  branch_name: null,
  confidential: false,
  create_note_path: '/gitlab-org/gitlab-foss/notes?target_id=98&target_type=issue',
  created_at: '2017-02-07T10:11:18.395Z',
  current_user: {
    can_create_note: true,
    can_update: true,
    can_award_emoji: true,
    can_create_confidential_note: true,
  },
  description: '',
  due_date: null,
  human_time_estimate: null,
  human_total_time_spent: null,
  id: 98,
  iid: 26,
  labels: [],
  lock_version: null,
  milestone: null,
  milestone_id: null,
  moved_to_id: null,
  preview_note_path: '/gitlab-org/gitlab-foss/preview_markdown?target_id=98&target_type=Issue',
  project_id: 2,
  state: 'opened',
  time_estimate: 0,
  title: '14',
  total_time_spent: 0,
  noteable_note_url: '/group/project/-/merge_requests/1#note_1',
  updated_at: '2017-08-04T09:53:01.226Z',
  updated_by_id: 1,
  web_url: '/gitlab-org/gitlab-foss/issues/26',
  noteableType: 'Issue',
  blocked_by_issues: [],
};

export const lastFetchedAt = '1501862675';

export const individualNote = {
  expanded: true,
  id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
  individual_note: true,
  notes: [
    {
      id: '1390',
      attachment: {
        url: null,
        filename: null,
        image: false,
      },
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: 'test',
        path: '/root',
      },
      created_at: '2017-08-01T17: 09: 33.762Z',
      updated_at: '2017-08-01T17: 09: 33.762Z',
      system: false,
      noteable_id: 98,
      noteable_type: 'Issue',
      type: null,
      human_access: 'Owner',
      note: 'sdfdsaf',
      note_html: "<p dir='auto'>sdfdsaf</p>",
      current_user: {
        can_edit: true,
        can_award_emoji: true,
      },
      discussion_id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
      emoji_awardable: true,
      award_emoji: [
        { name: 'baseball', user: { id: 1, name: 'Root', username: 'root' } },
        { name: 'art', user: { id: 1, name: 'Root', username: 'root' } },
      ],
      toggle_award_path: '/gitlab-org/gitlab-foss/notes/1390/toggle_award_emoji',
      noteable_note_url: '/group/project/-/merge_requests/1#note_1',
      note_url: '/group/project/-/merge_requests/1#note_1',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1390&user_id=1',
      path: '/gitlab-org/gitlab-foss/notes/1390',
    },
  ],
  reply_id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
};

export const note = {
  id: '546',
  attachment: {
    url: null,
    filename: null,
    image: false,
  },
  author: {
    id: 1,
    name: 'Administrator',
    username: 'root',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    path: '/root',
    user_type: 'human',
  },
  created_at: '2017-08-10T15:24:03.087Z',
  updated_at: '2017-08-10T15:24:03.087Z',
  system: false,
  imported: true,
  noteable_id: 67,
  noteable_type: 'Issue',
  noteable_iid: 7,
  type: null,
  human_access: 'Owner',
  note: 'Vel id placeat reprehenderit sit numquam.',
  note_html: '<p dir="auto">Vel id placeat reprehenderit sit numquam.</p>',
  current_user: {
    can_edit: true,
    can_award_emoji: true,
  },
  discussion_id: 'd3842a451b7f3d9a5dfce329515127b2d29a4cd0',
  emoji_awardable: true,
  award_emoji: [
    {
      name: 'baseball',
      user: {
        id: 1,
        name: 'Administrator',
        username: 'root',
      },
    },
    {
      name: 'bath_tone3',
      user: {
        id: 1,
        name: 'Administrator',
        username: 'root',
      },
    },
  ],
  toggle_award_path: '/gitlab-org/gitlab-foss/notes/546/toggle_award_emoji',
  note_url: '/group/project/-/merge_requests/1#note_1',
  noteable_note_url: '/group/project/-/merge_requests/1#note_1',
  report_abuse_path:
    '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F7%23note_546&user_id=1',
  path: '/gitlab-org/gitlab-foss/notes/546',
};

export const discussionMock = {
  id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
  reply_id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
  expanded: true,
  notes: [
    {
      id: '1395',
      attachment: {
        url: null,
        filename: null,
        image: false,
      },
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      created_at: '2017-08-02T10:51:58.559Z',
      updated_at: '2017-08-02T10:51:58.559Z',
      system: false,
      noteable_id: 98,
      noteable_type: 'Issue',
      type: 'DiscussionNote',
      human_access: 'Owner',
      note: 'THIS IS A DICUSSSION!',
      note_html: "<p dir='auto'>THIS IS A DICUSSSION!</p>",
      current_user: {
        can_edit: true,
        can_award_emoji: true,
        can_resolve: true,
        can_resolve_discussion: true,
      },
      discussion_id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
      emoji_awardable: true,
      award_emoji: [],
      noteable_note_url: '/group/project/-/merge_requests/1#note_1',
      toggle_award_path: '/gitlab-org/gitlab-foss/notes/1395/toggle_award_emoji',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1395&user_id=1',
      path: '/gitlab-org/gitlab-foss/notes/1395',
    },
    {
      id: '1396',
      attachment: {
        url: null,
        filename: null,
        image: false,
      },
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      created_at: '2017-08-02T10:56:50.980Z',
      updated_at: '2017-08-03T14:19:35.691Z',
      system: false,
      noteable_id: 98,
      noteable_type: 'Issue',
      type: 'DiscussionNote',
      human_access: 'Owner',
      note: 'sadfasdsdgdsf',
      note_html: "<p dir='auto'>sadfasdsdgdsf</p>",
      last_edited_at: '2017-08-03T14:19:35.691Z',
      last_edited_by: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      current_user: {
        can_edit: true,
        can_award_emoji: true,
        can_resolve: true,
        can_resolve_discussion: true,
      },
      discussion_id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
      emoji_awardable: true,
      award_emoji: [],
      toggle_award_path: '/gitlab-org/gitlab-foss/notes/1396/toggle_award_emoji',
      noteable_note_url: '/group/project/-/merge_requests/1#note_1',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1396&user_id=1',
      path: '/gitlab-org/gitlab-foss/notes/1396',
    },
    {
      id: '1437',
      attachment: {
        url: null,
        filename: null,
        image: false,
      },
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      created_at: '2017-08-03T18:11:18.780Z',
      updated_at: '2017-08-04T09:52:31.062Z',
      system: false,
      noteable_id: 98,
      noteable_type: 'Issue',
      type: 'DiscussionNote',
      human_access: 'Owner',
      note: 'adsfasf Should disappear',
      note_html: "<p dir='auto'>adsfasf Should disappear</p>",
      last_edited_at: '2017-08-04T09:52:31.062Z',
      last_edited_by: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      current_user: {
        can_edit: true,
        can_award_emoji: true,
        can_resolve: true,
        can_resolve_discussion: true,
      },
      discussion_id: '9e3bd2f71a01de45fd166e6719eb380ad9f270b1',
      emoji_awardable: true,
      award_emoji: [],
      noteable_note_url: '/group/project/-/merge_requests/1#note_1',
      toggle_award_path: '/gitlab-org/gitlab-foss/notes/1437/toggle_award_emoji',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1437&user_id=1',
      path: '/gitlab-org/gitlab-foss/notes/1437',
    },
  ],
  individual_note: false,
  resolvable: true,
  active: true,
  confidential: false,
};

export const loggedOutnoteableData = {
  id: '98',
  iid: 26,
  author_id: 1,
  description: '',
  lock_version: 1,
  milestone_id: null,
  state: 'opened',
  title: 'asdsa',
  updated_by_id: 1,
  created_at: '2017-02-07T10:11:18.395Z',
  updated_at: '2017-08-08T10:22:51.564Z',
  time_estimate: 0,
  total_time_spent: 0,
  human_time_estimate: null,
  human_total_time_spent: null,
  milestone: null,
  labels: [],
  branch_name: null,
  confidential: false,
  assignees: [
    {
      id: 1,
      name: 'Root',
      username: 'root',
      state: 'active',
      avatar_url: null,
      web_url: 'http://localhost:3000/root',
    },
  ],
  due_date: null,
  moved_to_id: null,
  project_id: 2,
  web_url: '/gitlab-org/gitlab-foss/issues/26',
  current_user: {
    can_create_note: false,
    can_update: false,
  },
  noteable_note_url: '/group/project/-/merge_requests/1#note_1',
  create_note_path: '/gitlab-org/gitlab-foss/notes?target_id=98&target_type=issue',
  preview_note_path: '/gitlab-org/gitlab-foss/preview_markdown?target_id=98&target_type=Issue',
};

export const collapseNotesMock = [
  {
    expanded: true,
    id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
    individual_note: true,
    notes: [
      {
        id: '1390',
        attachment: null,
        author: {
          id: 1,
          name: 'Root',
          username: 'root',
          state: 'active',
          avatar_url: 'test',
          path: '/root',
        },
        created_at: '2018-02-26T18:07:41.071Z',
        updated_at: '2018-02-26T18:07:41.071Z',
        system: true,
        system_note_icon_name: 'pencil',
        noteable_id: 98,
        noteable_type: 'Issue',
        type: null,
        human_access: 'Owner',
        note: 'changed the description',
        note_html: '<p dir="auto">changed the description</p>',
        current_user: { can_edit: false },
        discussion_id: 'b97fb7bda470a65b3e009377a9032edec0a4dd05',
        emoji_awardable: false,
        path: '/h5bp/html5-boilerplate/notes/1057',
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fh5bp%2Fhtml5-boilerplate%2Fissues%2F10%23note_1057&user_id=1',
      },
    ],
  },
  {
    expanded: true,
    id: 'ffde43f25984ad7f2b4275135e0e2846875336c0',
    individual_note: true,
    notes: [
      {
        id: '1391',
        attachment: null,
        author: {
          id: 1,
          name: 'Root',
          username: 'root',
          state: 'active',
          avatar_url: 'test',
          path: '/root',
        },
        created_at: '2018-02-26T18:13:24.071Z',
        updated_at: '2018-02-26T18:13:24.071Z',
        system: true,
        system_note_icon_name: 'pencil',
        noteable_id: 99,
        noteable_type: 'Issue',
        type: null,
        human_access: 'Owner',
        note: 'changed the description',
        note_html: '<p dir="auto">changed the description</p>',
        current_user: { can_edit: false },
        discussion_id: '3eb958b4d81dec207ec3537a2f3bd8b9f271bb34',
        emoji_awardable: false,
        path: '/h5bp/html5-boilerplate/notes/1057',
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fh5bp%2Fhtml5-boilerplate%2Fissues%2F10%23note_1057&user_id=1',
      },
    ],
  },
];

export const INDIVIDUAL_NOTE_RESPONSE_MAP = {
  GET: {
    '/gitlab-org/gitlab-foss/issues/26/discussions.json': [
      {
        id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
        reply_id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
        expanded: true,
        notes: [
          {
            id: '1390',
            attachment: {
              url: null,
              filename: null,
              image: false,
            },
            author: {
              id: 1,
              name: 'Root',
              username: 'root',
              state: 'active',
              avatar_url: null,
              path: '/root',
            },
            created_at: '2017-08-01T17:09:33.762Z',
            updated_at: '2017-08-01T17:09:33.762Z',
            system: false,
            noteable_id: 98,
            noteable_type: 'Issue',
            type: null,
            human_access: 'Owner',
            note: 'sdfdsaf',
            note_html: '\u003cp dir="auto"\u003esdfdsaf\u003c/p\u003e',
            current_user: {
              can_edit: true,
              can_award_emoji: true,
            },
            discussion_id: '0fb4e0e3f9276e55ff32eb4195add694aece4edd',
            emoji_awardable: true,
            award_emoji: [
              {
                name: 'baseball',
                user: {
                  id: 1,
                  name: 'Root',
                  username: 'root',
                },
              },
              {
                name: 'art',
                user: {
                  id: 1,
                  name: 'Root',
                  username: 'root',
                },
              },
            ],
            noteable_note_url: '/group/project/-/merge_requests/1#note_1',
            toggle_award_path: '/gitlab-org/gitlab-foss/notes/1390/toggle_award_emoji',
            report_abuse_path:
              '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1390\u0026user_id=1',
            path: '/gitlab-org/gitlab-foss/notes/1390',
          },
        ],
        individual_note: true,
      },
      {
        id: '70d5c92a4039a36c70100c6691c18c27e4b0a790',
        reply_id: '70d5c92a4039a36c70100c6691c18c27e4b0a790',
        expanded: true,
        notes: [
          {
            id: '1391',
            attachment: {
              url: null,
              filename: null,
              image: false,
            },
            author: {
              id: 1,
              name: 'Root',
              username: 'root',
              state: 'active',
              avatar_url: null,
              path: '/root',
            },
            created_at: '2017-08-02T10:51:38.685Z',
            updated_at: '2017-08-02T10:51:38.685Z',
            system: false,
            noteable_id: 98,
            noteable_type: 'Issue',
            type: null,
            human_access: 'Owner',
            note: 'New note!',
            note_html: '\u003cp dir="auto"\u003eNew note!\u003c/p\u003e',
            current_user: {
              can_edit: true,
              can_award_emoji: true,
            },
            discussion_id: '70d5c92a4039a36c70100c6691c18c27e4b0a790',
            emoji_awardable: true,
            award_emoji: [],
            noteable_note_url: '/group/project/-/merge_requests/1#note_1',
            toggle_award_path: '/gitlab-org/gitlab-foss/notes/1391/toggle_award_emoji',
            report_abuse_path:
              '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F26%23note_1391\u0026user_id=1',
            path: '/gitlab-org/gitlab-foss/notes/1391',
          },
        ],
        individual_note: true,
      },
    ],
    '/gitlab-org/gitlab-foss/noteable/issue/98/notes': {
      last_fetched_at: 1512900838,
      notes: [],
    },
  },
  PUT: {
    '/gitlab-org/gitlab-foss/notes/1471': {
      commands_changes: null,
      valid: true,
      id: '1471',
      attachment: null,
      author: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      created_at: '2017-08-08T16:53:00.666Z',
      updated_at: '2017-12-10T11:03:21.876Z',
      system: false,
      noteable_id: 124,
      noteable_type: 'Issue',
      noteable_iid: 29,
      type: 'DiscussionNote',
      human_access: 'Owner',
      note: 'Adding a comment',
      note_html: '\u003cp dir="auto"\u003eAdding a comment\u003c/p\u003e',
      last_edited_at: '2017-12-10T11:03:21.876Z',
      last_edited_by: {
        id: 1,
        name: 'Root',
        username: 'root',
        state: 'active',
        avatar_url: null,
        path: '/root',
      },
      current_user: {
        can_edit: true,
        can_award_emoji: true,
      },
      discussion_id: 'a3ed36e29b1957efb3b68c53e2d7a2b24b1df052',
      emoji_awardable: true,
      award_emoji: [],
      noteable_note_url: '/group/project/-/merge_requests/1#note_1',
      toggle_award_path: '/gitlab-org/gitlab-foss/notes/1471/toggle_award_emoji',
      report_abuse_path:
        '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F29%23note_1471\u0026user_id=1',
      path: '/gitlab-org/gitlab-foss/notes/1471',
    },
  },
};

export const DISCUSSION_NOTE_RESPONSE_MAP = {
  ...INDIVIDUAL_NOTE_RESPONSE_MAP,
  GET: {
    ...INDIVIDUAL_NOTE_RESPONSE_MAP.GET,
    '/gitlab-org/gitlab-foss/issues/26/discussions.json': [
      {
        id: 'a3ed36e29b1957efb3b68c53e2d7a2b24b1df052',
        reply_id: 'a3ed36e29b1957efb3b68c53e2d7a2b24b1df052',
        expanded: true,
        notes: [
          {
            id: '1471',
            attachment: {
              url: null,
              filename: null,
              image: false,
            },
            author: {
              id: 1,
              name: 'Root',
              username: 'root',
              state: 'active',
              avatar_url: null,
              path: '/root',
            },
            created_at: '2017-08-08T16:53:00.666Z',
            updated_at: '2017-08-08T16:53:00.666Z',
            system: false,
            noteable_id: 124,
            noteable_type: 'Issue',
            noteable_iid: 29,
            type: 'DiscussionNote',
            human_access: 'Owner',
            note: 'Adding a comment',
            note_html: '\u003cp dir="auto"\u003eAdding a comment\u003c/p\u003e',
            current_user: {
              can_edit: true,
              can_award_emoji: true,
            },
            discussion_id: 'a3ed36e29b1957efb3b68c53e2d7a2b24b1df052',
            emoji_awardable: true,
            award_emoji: [],
            toggle_award_path: '/gitlab-org/gitlab-foss/notes/1471/toggle_award_emoji',
            noteable_note_url: '/group/project/-/merge_requests/1#note_1',
            report_abuse_path:
              '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F29%23note_1471\u0026user_id=1',
            path: '/gitlab-org/gitlab-foss/notes/1471',
          },
        ],
        individual_note: false,
      },
    ],
  },
};

export function getIndividualNoteResponse(config) {
  return [HTTP_STATUS_OK, INDIVIDUAL_NOTE_RESPONSE_MAP[config.method.toUpperCase()][config.url]];
}

export function getDiscussionNoteResponse(config) {
  return [HTTP_STATUS_OK, DISCUSSION_NOTE_RESPONSE_MAP[config.method.toUpperCase()][config.url]];
}

export const notesWithDescriptionChanges = [
  {
    id: '39b271c2033e9ed43d8edb393702f65f7a830459',
    reply_id: '39b271c2033e9ed43d8edb393702f65f7a830459',
    expanded: true,
    notes: [
      {
        id: '901',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:05:36.117Z',
        updated_at: '2018-05-29T12:05:36.117Z',
        system: false,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        note_html:
          '<p dir="auto">Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>',
        current_user: { can_edit: true, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        discussion_id: '39b271c2033e9ed43d8edb393702f65f7a830459',
        emoji_awardable: true,
        award_emoji: [],
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_901&user_id=1',
        human_access: 'Owner',
        toggle_award_path: '/gitlab-org/gitlab-shell/notes/901/toggle_award_emoji',
        path: '/gitlab-org/gitlab-shell/notes/901',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
  {
    id: '4852335d7dc40b9ceb8fde1a2bb9c1b67e4c7795',
    reply_id: '4852335d7dc40b9ceb8fde1a2bb9c1b67e4c7795',
    expanded: true,
    notes: [
      {
        id: '902',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:05:58.694Z',
        updated_at: '2018-05-29T12:05:58.694Z',
        system: false,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'Varius vel pharetra vel turpis nunc eget lorem. Ipsum dolor sit amet consectetur adipiscing.',
        note_html:
          '<p dir="auto">Varius vel pharetra vel turpis nunc eget lorem. Ipsum dolor sit amet consectetur adipiscing.</p>',
        current_user: { can_edit: true, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        discussion_id: '4852335d7dc40b9ceb8fde1a2bb9c1b67e4c7795',
        emoji_awardable: true,
        award_emoji: [],
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_902&user_id=1',
        human_access: 'Owner',
        toggle_award_path: '/gitlab-org/gitlab-shell/notes/902/toggle_award_emoji',
        path: '/gitlab-org/gitlab-shell/notes/902',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
  {
    id: '7f1feda384083eb31763366e6392399fde6f3f31',
    reply_id: '7f1feda384083eb31763366e6392399fde6f3f31',
    expanded: true,
    notes: [
      {
        id: '903',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:06:05.772Z',
        updated_at: '2018-05-29T12:06:05.772Z',
        system: true,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'changed the description',
        note_html: '<p dir="auto">changed the description</p>',
        current_user: { can_edit: false, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        system_note_icon_name: 'pencil',
        discussion_id: '7f1feda384083eb31763366e6392399fde6f3f31',
        emoji_awardable: false,
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_903&user_id=1',
        human_access: 'Owner',
        path: '/gitlab-org/gitlab-shell/notes/903',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
  {
    id: '091865fe3ae20f0045234a3d103e3b15e73405b5',
    reply_id: '091865fe3ae20f0045234a3d103e3b15e73405b5',
    expanded: true,
    notes: [
      {
        id: '904',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:06:16.112Z',
        updated_at: '2018-05-29T12:06:16.112Z',
        system: false,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'Ullamcorper eget nulla facilisi etiam',
        note_html: '<p dir="auto">Ullamcorper eget nulla facilisi etiam</p>',
        current_user: { can_edit: true, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        discussion_id: '091865fe3ae20f0045234a3d103e3b15e73405b5',
        emoji_awardable: true,
        award_emoji: [],
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_904&user_id=1',
        human_access: 'Owner',
        toggle_award_path: '/gitlab-org/gitlab-shell/notes/904/toggle_award_emoji',
        path: '/gitlab-org/gitlab-shell/notes/904',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
  {
    id: 'a21cf2e804acc3c60d07e37d75e395f5a9a4d044',
    reply_id: 'a21cf2e804acc3c60d07e37d75e395f5a9a4d044',
    expanded: true,
    notes: [
      {
        id: '905',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:06:28.851Z',
        updated_at: '2018-05-29T12:06:28.851Z',
        system: true,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'changed the description',
        note_html: '<p dir="auto">changed the description</p>',
        current_user: { can_edit: false, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        system_note_icon_name: 'pencil',
        discussion_id: 'a21cf2e804acc3c60d07e37d75e395f5a9a4d044',
        emoji_awardable: false,
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_905&user_id=1',
        human_access: 'Owner',
        path: '/gitlab-org/gitlab-shell/notes/905',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
  {
    id: '70411b08cdfc01f24187a06d77daa33464cb2620',
    reply_id: '70411b08cdfc01f24187a06d77daa33464cb2620',
    expanded: true,
    notes: [
      {
        id: '906',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:20:02.925Z',
        updated_at: '2018-05-29T12:20:02.925Z',
        system: true,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'changed the description',
        note_html: '<p dir="auto">changed the description</p>',
        current_user: { can_edit: false, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        system_note_icon_name: 'pencil',
        discussion_id: '70411b08cdfc01f24187a06d77daa33464cb2620',
        emoji_awardable: false,
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_906&user_id=1',
        human_access: 'Owner',
        path: '/gitlab-org/gitlab-shell/notes/906',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
];

export const collapsedSystemNotes = [
  {
    id: '39b271c2033e9ed43d8edb393702f65f7a830459',
    reply_id: '39b271c2033e9ed43d8edb393702f65f7a830459',
    expanded: true,
    notes: [
      {
        id: '901',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:05:36.117Z',
        updated_at: '2018-05-29T12:05:36.117Z',
        system: false,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
        note_html:
          '<p dir="auto">Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>',
        current_user: { can_edit: true, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        discussion_id: '39b271c2033e9ed43d8edb393702f65f7a830459',
        emoji_awardable: true,
        award_emoji: [],
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_901&user_id=1',
        human_access: 'Owner',
        toggle_award_path: '/gitlab-org/gitlab-shell/notes/901/toggle_award_emoji',
        path: '/gitlab-org/gitlab-shell/notes/901',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
  {
    id: '4852335d7dc40b9ceb8fde1a2bb9c1b67e4c7795',
    reply_id: '4852335d7dc40b9ceb8fde1a2bb9c1b67e4c7795',
    expanded: true,
    notes: [
      {
        id: '902',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:05:58.694Z',
        updated_at: '2018-05-29T12:05:58.694Z',
        system: false,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'Varius vel pharetra vel turpis nunc eget lorem. Ipsum dolor sit amet consectetur adipiscing.',
        note_html:
          '<p dir="auto">Varius vel pharetra vel turpis nunc eget lorem. Ipsum dolor sit amet consectetur adipiscing.</p>',
        current_user: { can_edit: true, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        discussion_id: '4852335d7dc40b9ceb8fde1a2bb9c1b67e4c7795',
        emoji_awardable: true,
        award_emoji: [],
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_902&user_id=1',
        human_access: 'Owner',
        toggle_award_path: '/gitlab-org/gitlab-shell/notes/902/toggle_award_emoji',
        path: '/gitlab-org/gitlab-shell/notes/902',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
  {
    id: '091865fe3ae20f0045234a3d103e3b15e73405b5',
    reply_id: '091865fe3ae20f0045234a3d103e3b15e73405b5',
    expanded: true,
    notes: [
      {
        id: '904',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:06:16.112Z',
        updated_at: '2018-05-29T12:06:16.112Z',
        system: false,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'Ullamcorper eget nulla facilisi etiam',
        note_html: '<p dir="auto">Ullamcorper eget nulla facilisi etiam</p>',
        current_user: { can_edit: true, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        discussion_id: '091865fe3ae20f0045234a3d103e3b15e73405b5',
        emoji_awardable: true,
        award_emoji: [],
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_904&user_id=1',
        human_access: 'Owner',
        toggle_award_path: '/gitlab-org/gitlab-shell/notes/904/toggle_award_emoji',
        path: '/gitlab-org/gitlab-shell/notes/904',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
  {
    id: 'a21cf2e804acc3c60d07e37d75e395f5a9a4d044',
    reply_id: 'a21cf2e804acc3c60d07e37d75e395f5a9a4d044',
    expanded: true,
    notes: [
      {
        id: '905',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:06:28.851Z',
        updated_at: '2018-05-29T12:06:28.851Z',
        system: true,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        start_description_version_id: undefined,
        note: 'changed the description',
        note_html: '<p dir="auto">changed the description</p>',
        current_user: { can_edit: false, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        system_note_icon_name: 'pencil',
        discussion_id: 'a21cf2e804acc3c60d07e37d75e395f5a9a4d044',
        emoji_awardable: false,
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_905&user_id=1',
        human_access: 'Owner',
        path: '/gitlab-org/gitlab-shell/notes/905',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
  {
    id: '70411b08cdfc01f24187a06d77daa33464cb2620',
    reply_id: '70411b08cdfc01f24187a06d77daa33464cb2620',
    expanded: true,
    notes: [
      {
        id: '906',
        type: null,
        attachment: null,
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          path: '/root',
        },
        created_at: '2018-05-29T12:20:02.925Z',
        updated_at: '2018-05-29T12:20:02.925Z',
        system: true,
        noteable_id: 182,
        noteable_type: 'Issue',
        resolvable: false,
        noteable_iid: 12,
        note: 'changed the description',
        note_html: '<p dir="auto">changed the description</p>',
        current_user: { can_edit: false, can_award_emoji: true },
        resolved: false,
        resolved_by: null,
        system_note_icon_name: 'pencil',
        discussion_id: '70411b08cdfc01f24187a06d77daa33464cb2620',
        emoji_awardable: false,
        report_abuse_path:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-shell%2Fissues%2F12%23note_906&user_id=1',
        human_access: 'Owner',
        path: '/gitlab-org/gitlab-shell/notes/906',
      },
    ],
    individual_note: true,
    resolvable: false,
    resolved: false,
    diff_discussion: false,
  },
];

export const discussion1 = {
  id: 'abc1',
  resolvable: true,
  resolved: false,
  active: true,
  diff_file: {
    file_identifier_hash: 'discfile1',
  },
  position: {
    new_line: 50,
    old_line: null,
  },
  notes: [
    {
      created_at: '2018-07-04T16:25:41.749Z',
    },
  ],
};

export const resolvedDiscussion1 = {
  id: 'abc1',
  resolvable: true,
  resolved: true,
  diff_file: {
    file_identifier_hash: 'discfile1',
  },
  position: {
    new_line: 50,
    old_line: null,
  },
  notes: [
    {
      created_at: '2018-07-04T16:25:41.749Z',
    },
  ],
};

export const discussion2 = {
  id: 'abc2',
  resolvable: true,
  resolved: false,
  active: true,
  diff_file: {
    file_identifier_hash: 'discfile2',
  },
  position: {
    new_line: null,
    old_line: 20,
  },
  notes: [
    {
      created_at: '2018-07-04T12:05:41.749Z',
    },
  ],
};

export const discussion3 = {
  id: 'abc3',
  resolvable: true,
  active: true,
  resolved: false,
  diff_file: {
    file_identifier_hash: 'discfile3',
  },
  position: {
    new_line: 21,
    old_line: null,
  },
  notes: [
    {
      created_at: '2018-07-05T17:25:41.749Z',
    },
  ],
};

export const authoritativeDiscussionFile = {
  id: 'abc',
  file_identifier_hash: 'discfile1',
  order: 0,
};

export const unresolvableDiscussion = {
  resolvable: false,
};

export const discussionFiltersMock = [
  {
    title: 'Show all activity',
    value: 0,
  },
  {
    title: 'Show comments only',
    value: 1,
  },
  {
    title: 'Show system notes only',
    value: 2,
  },
];

export const batchSuggestionsInfoMock = [
  {
    suggestionId: 'a123',
    noteId: 'b456',
    discussionId: 'c789',
  },
  {
    suggestionId: 'a001',
    noteId: 'b002',
    discussionId: 'c003',
  },
];

export const draftComments = [
  { id: 7, note: 'test draft note', isDraft: true },
  { id: 9, note: 'draft note 2', isDraft: true },
];

export const draftReply = { id: 8, note: 'draft reply', discussion_id: 1, isDraft: true };

export const draftDiffDiscussion = {
  id: 6,
  note: 'draft diff discussion',
  line_code: 1,
  file_path: 'lib/foo.rb',
  isDraft: true,
};

export const notesFilters = [
  {
    title: 'Show all activity',
    value: 0,
  },
  {
    title: 'Show comments only',
    value: 1,
  },
  {
    title: 'Show history only',
    value: 2,
  },
];

export const singleNoteResponseFactory = ({ urlHash, authorId = 1 } = {}) => {
  const id = urlHash?.replace('note_', '') || '5678';
  return {
    data: {
      note: {
        id: `gid://gitlab/Note/${id}`,
        discussion: {
          id: 'gid://gitlab/Discussion/1',
          notes: {
            nodes: [
              {
                id: `gid://gitlab/Note/${id}`,
                author: {
                  id: `gid://gitlab/User/${authorId}`,
                  name: 'Administrator',
                  username: 'root',
                  avatar_url: '',
                  web_url: '',
                  web_path: '',
                },
                award_emoji: {
                  nodes: [
                    {
                      emoji: 'test',
                      name: 'test',
                      user: {
                        id: 'gid://gitlab/User/1',
                        name: 'Administrator',
                        username: 'root',
                        avatar_url: '',
                        web_url: '',
                        web_path: '',
                      },
                    },
                  ],
                },
                note_html: 'my quick note',
                created_at: '2020-01-01T10:00:00.000Z',
                last_edited_at: null,
                last_edited_by: null,
                internal: false,
                url: '/note/1',
                userPermissions: {
                  awardEmoji: true,
                  adminNote: true,
                  readNote: true,
                  createNote: true,
                  resolveNote: true,
                },
              },
            ],
          },
        },
      },
    },
  };
};
