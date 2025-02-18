export const pageInfo = {
  lastCommitSha: '5232645eff8b69ca6a76d79f0d15c0829dc9a137',
  persisted: true,
  title: 'home',
  content:
    "# Welcome to Our Wiki!\r\n\r\nThis wiki is a collaborative resource for information about [Project Name/Topic]. \r\n\r\n**Here you'll find:**\r\n\r\n* **Getting Started:**\r\n    * [Installation Guide](/installation)\r\n    * [Quick Start Tutorial](/quickstart)\r\n    * [FAQ](/faq)\r\n* **User Guides:**\r\n    * [Basic Usage](/basic-usage)\r\n    * [Advanced Features](/advanced-features)\r\n    * [Troubleshooting](/troubleshooting)\r\n* **Developer Documentation:**\r\n    * [API Reference](/api)\r\n    * [Contributing Guidelines](/contributing)\r\n    * [Code Style Guide](/code-style)\r\n\r\n**Navigation:**\r\n\r\n* Use the sidebar to browse pages.\r\n* Use the search bar to find specific topics.\r\n\r\n**Contributing:**\r\n\r\nWe encourage you to contribute to this wiki! If you find any errors, have suggestions for improvements, or want to add new content, please feel free to [submit a pull request](/contributing).\r\n\r\n**Let's build a comprehensive knowledge base together!**\r\n\r\n---\r\n\r\n**Recent Updates:**\r\n\r\n* **[Date]:** Added information about [new feature/update].\r\n* **[Date]:** Updated the [page name] page.\r\n* **[Date]:** Fixed a typo on the [page name] page.\r\n\r\n---\r\n\r\n**Contact:**\r\n\r\n* **Email:** [email address]\r\n* **Website:** [website address]",
  frontMatter: {},
  format: 'markdown',
  uploadsPath: 'http://127.0.0.1:3000/api/v4/projects/7/wikis/attachments',
  slug: 'home',
  path: '/flightjs/Flight/-/wikis/home',
  wikiPath: '/flightjs/Flight/-/wikis/home',
  helpPath: '/help/user/project/wiki/_index.md',
  markdownHelpPath: '/help/user/markdown.md',
  markdownPreviewPath: '/flightjs/Flight/-/wikis/home/preview_markdown',
  createPath: '/flightjs/Flight/-/wikis',
};
const registerPath = '/users/sign_up?redirect_to_referer=yes';
const signInPath = '/users/sign_in?redirect_to_referer=yes';
export const noteableType = 'Wiki';
export const currentUserData = {
  id: 70,
  username: 'test_user1',
  name: 'Tester1',
  state: 'active',
  locked: false,
  avatar_url:
    'https://www.gravatar.com/avatar/87924606b4131a8aceeeae8868531fbb9712aaa07a5d3a756b26ce0f5d6ca674?s=80&d=identicon',
  web_url: 'http://127.0.0.1:3000/test_user1',
  show_status: false,
  path: '/test_user1',
  user_preference: {
    issue_notes_filter: 0,
    merge_request_notes_filter: 0,
    notes_filters: {
      'Show all activity': 0,
      'Show comments only': 1,
      'Show history only': 2,
    },
    default_notes_filter: 0,
    epic_notes_filter: 0,
  },
};
const markdownPreviewPath = '/flightjs/Flight/-/preview_markdown';
const markdownDocsPath = '/help/user/markdown.md';
const isContainerArchived = false;

export const note = {
  __typename: 'Note',
  id: 'gid://gitlab/DiscussionNote/1524',
  author: {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    avatarUrl:
      'https://www.gravatar.com/avatar/0a39b28b2f7a0822118ef3ea2454128ccb1b7c36e34fb1b3665c353ef58e95da?s=80&d=identicon',
    name: 'Administrator',
    username: 'root',
    webUrl: 'http://127.0.0.1:3000/root',
    webPath: '/root',
  },
  body: 'an example note',
  bodyHtml: '<p data-sourcepos="1:1-1:29" dir="auto">an example note</p>',
  createdAt: '2024-11-10T14:19:58Z',
  lastEditedAt: '2024-11-10T14:19:58Z',
  url: 'http://127.0.0.1:3000/flightjs/Flight/-/wikis/home#note_1524',
  userPermissions: {
    __typename: 'NotePermissions',
    adminNote: false,
    awardEmoji: false,
    readNote: true,
    createNote: true,
    resolveNote: false,
    repositionNote: false,
  },
  discussion: {
    __typename: 'Discussion',
    id: 'gid://gitlab/Discussion/d3146d41c7bec5bdad8ecc9f41c5f9121cd19f56',
    resolved: false,
    resolvable: true,
    resolvedBy: null,
  },
  awardEmoji: {
    nodes: [],
  },
};

export const awardEmoji = {
  name: 'star',
  user: {
    id: 70,
    name: 'user1',
  },
  __typename: 'AwardEmoji',
};

export const noteableId = '7';

export const queryVariables = { slug: 'home', projectId: 'gid://gitlab/Group/7' };

export const wikiCommentFormProvideData = {
  pageInfo,
  registerPath,
  signInPath,
  currentUserData,
  markdownPreviewPath,
  noteableType,
  markdownDocsPath,
  isContainerArchived,
};
