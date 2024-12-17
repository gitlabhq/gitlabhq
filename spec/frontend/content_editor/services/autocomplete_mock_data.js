export const MOCK_MEMBERS = [
  {
    type: 'User',
    username: 'florida.schoen',
    name: 'Anglea Durgan',
    avatar_url:
      'https://www.gravatar.com/avatar/ac82b5615d3308ecbcacedad361af8e7?s=80\u0026d=identicon',
    availability: null,
  },
  {
    type: 'User',
    username: 'root',
    name: 'Administrator',
    avatar_url:
      'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
    availability: null,
  },
  {
    username: 'all',
    name: 'All Project and Group Members',
    count: 8,
  },
  {
    type: 'User',
    username: 'errol',
    name: "Linnie O'Connell",
    avatar_url:
      'https://www.gravatar.com/avatar/d3d9a468a9884eb217fad5ca5b2b9bd7?s=80\u0026d=identicon',
    availability: null,
  },
  {
    type: 'User',
    username: 'evelynn_olson',
    name: 'Dimple Dare',
    avatar_url:
      'https://www.gravatar.com/avatar/bc1e51ee3512c2b4442f51732d655107?s=80\u0026d=identicon',
    availability: null,
  },
  {
    type: 'User',
    username: 'lakeesha.batz',
    name: 'Larae Veum',
    avatar_url:
      'https://www.gravatar.com/avatar/e5605cb9bbb1a28640d65f25f256e541?s=80\u0026d=identicon',
    availability: null,
  },
  {
    type: 'User',
    username: 'laurene_blick',
    name: 'Evelina Murray',
    avatar_url:
      'https://www.gravatar.com/avatar/389768eef61b7b2d125c64ee01c240fb?s=80\u0026d=identicon',
    availability: null,
  },
  {
    type: 'User',
    username: 'myrtis',
    name: 'Fernanda Adams',
    avatar_url:
      'https://www.gravatar.com/avatar/719d5569bd31d4a70e350b4205fa2cb5?s=80\u0026d=identicon',
    availability: null,
  },
  {
    type: 'User',
    username: 'patty',
    name: 'Emily Toy',
    avatar_url:
      'https://www.gravatar.com/avatar/dca2077b662338808459dc11e70d6688?s=80\u0026d=identicon',
    availability: null,
  },
  {
    type: 'Group',
    username: 'Commit451',
    name: 'Commit451',
    avatar_url: null,
    count: 5,
    mentionsDisabled: null,
  },
  {
    type: 'Group',
    username: 'flightjs',
    name: 'Flightjs',
    avatar_url: null,
    count: 5,
    mentionsDisabled: null,
  },
  {
    type: 'Group',
    username: 'gitlab-instance-ade037f9',
    name: 'GitLab Instance',
    avatar_url: null,
    count: 1,
    mentionsDisabled: null,
  },
  {
    type: 'Group',
    username: 'gitlab-org',
    name: 'Gitlab Org',
    avatar_url: null,
    count: 5,
    mentionsDisabled: null,
  },
  {
    type: 'Group',
    username: 'gnuwget',
    name: 'Gnuwget',
    avatar_url: null,
    count: 5,
    mentionsDisabled: null,
  },
  {
    type: 'Group',
    username: 'h5bp',
    name: 'H5bp',
    avatar_url: null,
    count: 4,
    mentionsDisabled: null,
  },
  {
    type: 'Group',
    username: 'jashkenas',
    name: 'Jashkenas',
    avatar_url: null,
    count: 5,
    mentionsDisabled: null,
  },
  {
    type: 'Group',
    username: 'twitter',
    name: 'Twitter',
    avatar_url: null,
    count: 5,
    mentionsDisabled: null,
  },
];

export const MOCK_ASSIGNEES = MOCK_MEMBERS.filter(
  ({ username }) => username === 'errol' || username === 'evelynn_olson',
);

export const MOCK_REVIEWERS = MOCK_MEMBERS.filter(
  ({ username }) =>
    username === 'lakeesha.batz' ||
    username === 'laurene_blick' ||
    username === 'myrtis' ||
    username === 'patty',
);

export const MOCK_ISSUES = [
  {
    iid: 31,
    title: 'rdfhdfj',
    id: null,
  },
  {
    iid: 30,
    title: 'incident1',
    id: null,
  },
  {
    iid: 29,
    title: 'example feature rollout',
    id: null,
  },
  {
    iid: 28,
    title: 'sagasg',
    id: null,
  },
  {
    iid: 26,
    title: 'Quasi id et et nihil sint autem.',
    id: null,
  },
  {
    iid: 25,
    title: 'Dolorem quisquam cupiditate consequatur perspiciatis sequi eligendi ullam.',
    id: null,
  },
  {
    iid: 24,
    title: 'Et molestiae delectus voluptates velit vero illo aut rerum quo et.',
    id: null,
  },
  {
    iid: 23,
    title: 'Nesciunt quia molestiae in aliquam amet et dolorem.',
    id: null,
  },
  {
    iid: 22,
    title: 'Sint asperiores unde vel autem delectus ullam dolor nihil et.',
    id: null,
  },
  {
    iid: 21,
    title: 'Eaque omnis eius quas necessitatibus hic ut et corrupti.',
    id: null,
  },
  {
    iid: 20,
    title: 'Porro tempore qui qui culpa saepe et nam quos.',
    id: null,
  },
  {
    iid: 19,
    title: 'Molestiae minima maxime optio nihil quam eveniet dolor.',
    id: null,
  },
  {
    iid: 18,
    title: 'Sed sint a est consequatur quae quasi autem debitis alias.',
    id: null,
  },
  {
    iid: 6,
    title: 'Et laboriosam aut ratione voluptatem quasi recusandae.',
    id: null,
  },
  {
    iid: 2,
    title: 'Aut quisquam magnam eos distinctio incidunt perferendis fugit.',
    id: null,
  },
];

export const MOCK_EPICS = [
  {
    iid: 6,
    title: 'sgs',
    reference: 'flightjs\u00266',
  },
  {
    iid: 5,
    title: 'Doloremque a quisquam qui culpa numquam doloribus similique iure enim.',
    reference: 'flightjs\u00265',
  },
  {
    iid: 4,
    title: 'Minus eius ut omnis quos sunt dicta ex ipsum.',
    reference: 'flightjs\u00264',
  },
  {
    iid: 3,
    title: 'Quae nostrum possimus rerum aliquam pariatur a eos aut id.',
    reference: 'flightjs\u00263',
  },
  {
    iid: 2,
    title: 'Nobis quidem aspernatur reprehenderit sunt ut ipsum tempora sapiente sed iste.',
    reference: 'flightjs\u00262',
  },
  {
    iid: 1,
    title: 'Dicta incidunt vel dignissimos sint sit esse est quibusdam quidem consequatur.',
    reference: 'flightjs\u00261',
  },
];

export const MOCK_MERGE_REQUESTS = [
  {
    iid: 12,
    title: "Always call registry's trigger method from withRegistration",
    id: null,
  },
  {
    iid: 11,
    title: 'Draft: Alunny/publish lib',
    id: null,
  },
  {
    iid: 10,
    title: 'Draft: Resolve "hgvbbvnnb"',
    id: null,
  },
  {
    iid: 9,
    title: 'Draft: Fix event current target',
    id: null,
  },
  {
    iid: 3,
    title: 'Autem eaque et sed provident enim corrupti molestiae.',
    id: null,
  },
  {
    iid: 2,
    title: 'Blanditiis maxime voluptatem ut pariatur vel autem vero non quod libero.',
    id: null,
  },
  {
    iid: 1,
    title: 'Optio nemo qui dolorem sit ipsum qui saepe.',
    id: null,
  },
];

export const MOCK_SNIPPETS = [
  {
    id: 24,
    title: 'ss',
  },
  {
    id: 22,
    title: 'another test snippet',
  },
  {
    id: 21,
    title: 'test snippet',
  },
];

export const MOCK_LABELS = [
  {
    title: 'Amsche',
    color: '#9964cf',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
    set: true,
  },
  {
    title: 'Brioffe',
    color: '#203e13',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
    set: true,
  },
  {
    title: 'Bronce',
    color: '#c0b7f2',
    type: 'GroupLabel',
    textColor: '#1F1E24',
  },
  {
    title: 'Bryncefunc',
    color: '#8baa5e',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
    set: true,
  },
  {
    title: 'Contour',
    color: '#8cf3a3',
    type: 'ProjectLabel',
    textColor: '#1F1E24',
  },
  {
    title: 'Corolla',
    color: '#0384f3',
    type: 'ProjectLabel',
    textColor: '#FFFFFF',
  },
  {
    title: 'Cygsync',
    color: '#1308c3',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
  },
  {
    title: 'Frontier',
    color: '#85db43',
    type: 'ProjectLabel',
    textColor: '#1F1E24',
  },
  {
    title: 'Ghost',
    color: '#df1bc4',
    type: 'ProjectLabel',
    textColor: '#FFFFFF',
    set: true,
  },
  {
    title: 'Grand Am',
    color: '#a1d7ee',
    type: 'ProjectLabel',
    textColor: '#1F1E24',
  },
  {
    title: 'Onesync',
    color: '#a73ba0',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
  },
  {
    title: 'Phone',
    color: '#63dceb',
    type: 'GroupLabel',
    textColor: '#1F1E24',
  },
  {
    title: 'Pynefunc',
    color: '#974b19',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
  },
  {
    title: 'Trinix',
    color: '#2c894f',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
  },
  {
    title: 'Trounswood',
    color: '#ad0370',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
  },
  {
    title: 'group::knowledge',
    color: '#8fbc8f',
    type: 'ProjectLabel',
    textColor: '#1F1E24',
  },
  {
    title: 'scoped label',
    color: '#6699cc',
    type: 'GroupLabel',
    textColor: '#FFFFFF',
  },
  {
    title: 'type::one',
    color: '#9400d3',
    type: 'ProjectLabel',
    textColor: '#FFFFFF',
  },
  {
    title: 'type::two',
    color: '#013220',
    type: 'ProjectLabel',
    textColor: '#FFFFFF',
  },
];

export const MOCK_MILESTONES = [
  {
    iid: 65,
    title: '15.0',
    due_date: '2022-05-17',
    id: null,
  },
  {
    iid: 73,
    title: '15.1',
    due_date: '2022-06-17',
    id: null,
  },
  {
    iid: 74,
    title: '15.2',
    due_date: '2022-07-17',
    id: null,
  },
  {
    iid: 75,
    title: '15.3',
    due_date: '2022-08-17',
    id: null,
  },
  {
    iid: 76,
    title: '15.4',
    due_date: '2022-09-17',
    id: null,
  },
  {
    iid: 77,
    title: '15.5',
    due_date: '2022-10-17',
    id: null,
  },
  {
    iid: 81,
    title: '15.6',
    due_date: '2022-11-17',
    id: null,
  },
  {
    iid: 82,
    title: '15.7',
    due_date: '2022-12-17',
    id: null,
  },
  {
    iid: 83,
    title: '15.8',
    due_date: '2023-01-17',
    id: null,
  },
  {
    iid: 84,
    title: '15.9',
    due_date: '2023-02-17',
    id: null,
  },
  {
    iid: 85,
    title: '15.10',
    due_date: '2023-03-17',
    id: null,
  },
  {
    iid: 86,
    title: '15.11',
    due_date: '2023-04-17',
    id: null,
  },
  {
    iid: 80,
    title: '16.0',
    due_date: '2023-05-17',
    id: null,
  },
  {
    iid: 88,
    title: '16.1',
    due_date: '2023-06-17',
    id: null,
  },
  {
    iid: 89,
    title: '16.2',
    due_date: '2023-07-17',
    id: null,
  },
  {
    iid: 90,
    title: '16.3',
    due_date: '2023-08-17',
    id: null,
  },
  {
    iid: 91,
    title: '16.4',
    due_date: '2023-09-17',
    id: null,
  },
  {
    iid: 92,
    title: '16.5',
    due_date: '2023-10-17',
    id: null,
  },
  {
    iid: 93,
    title: '16.6',
    due_date: '2023-11-10',
    id: null,
  },
  {
    iid: 95,
    title: '16.7',
    due_date: '2023-12-15',
    id: null,
  },
  {
    iid: 94,
    title: '16.8',
    due_date: '2024-01-12',
    id: null,
  },
  {
    iid: 96,
    title: '16.9',
    due_date: '2024-02-09',
    id: null,
  },
  {
    iid: 97,
    title: '16.10',
    due_date: '2024-03-15',
    id: null,
  },
  {
    iid: 98,
    title: '16.11',
    due_date: '2024-04-12',
    id: null,
  },
  {
    iid: 87,
    title: '17.0',
    due_date: '2024-05-10',
    id: null,
  },
  {
    iid: 48,
    title: 'Next 1-3 releases',
    due_date: null,
    id: null,
  },
  {
    iid: 24,
    title: 'Awaiting further demand',
    due_date: null,
    id: null,
  },
  {
    iid: 14,
    title: 'Backlog',
    due_date: null,
    id: null,
  },
  {
    iid: 11,
    title: 'Next 4-7 releases',
    due_date: null,
    id: null,
  },
  {
    iid: 10,
    title: 'Next 3-4 releases',
    due_date: null,
    id: null,
  },
  {
    iid: 6,
    title: 'Next 7-13 releases',
    due_date: null,
    id: null,
  },
];

export const MOCK_ITERATIONS = [
  {
    id: 2747,
    title: 'Optio quod at quia ad pariatur dolores. Nov 26, 2024 - Dec 9, 2024',
    reference: '*iteration:2747',
  },
  {
    id: 2910,
    title:
      'Architecto illum debitis perspiciatis vero itaque consectetur. Nov 12, 2024 - Dec 9, 2024',
    reference: '*iteration:2910',
  },
  {
    id: 3141,
    title: 'Assumenda rerum neque quisquam amet eius pariatur dolor. Nov 12, 2024 - Dec 9, 2024',
    reference: '*iteration:3141',
  },
  {
    id: 3236,
    title:
      'Quasi neque blanditiis necessitatibus incidunt at provident nam ea totam rem. Nov 26, 2024 - Dec 9, 2024',
    reference: '*iteration:3236',
  },
  {
    id: 3254,
    title:
      'Labore similique at sunt repellendus aut eveniet blanditiis esse. Nov 12, 2024 - Dec 9, 2024',
    reference: '*iteration:3254',
  },
  {
    id: 3282,
    title:
      'Dolorum eos maiores quidem eveniet adipisci reprehenderit odit minus dolore. Nov 12, 2024 - Dec 9, 2024',
    reference: '*iteration:3282',
  },
  {
    id: 3380,
    title:
      'Eaque quis officia itaque vitae repellat libero aliquid eum eligendi. Nov 12, 2024 - Dec 9, 2024',
    reference: '*iteration:3380',
  },
  {
    id: 3385,
    title:
      'Ducimus praesentium doloribus perspiciatis quis soluta natus. Nov 26, 2024 - Dec 9, 2024',
    reference: '*iteration:3385',
  },
  {
    id: 6191,
    title: 'Quibusdam est culpa dolores quisquam possimus nihil ut. Dec 3, 2024 - Dec 9, 2024',
    reference: '*iteration:6191',
  },
  {
    id: 6220,
    title:
      'Saepe provident facere veniam maiores excepturi assumenda adipisci beatae vitae aspernatur. Dec 3, 2024 - Dec 9, 2024',
    reference: '*iteration:6220',
  },
  {
    id: 6338,
    title: 'Illo ipsa excepturi beatae impedit ad architecto doloribus. Dec 3, 2024 - Dec 9, 2024',
    reference: '*iteration:6338',
  },
  {
    id: 2755,
    title:
      'Itaque repellat possimus dolor quia nesciunt hic aut iure animi vel. Nov 13, 2024 - Dec 10, 2024',
    reference: '*iteration:2755',
  },
  {
    id: 2789,
    title:
      'Magni eos minus vero facilis in consequuntur deserunt omnis consectetur natus. Nov 27, 2024 - Dec 10, 2024',
    reference: '*iteration:2789',
  },
  {
    id: 3061,
    title:
      'Dolores accusantium omnis dicta aliquam exercitationem sed laudantium placeat repellat. Nov 13, 2024 - Dec 10, 2024',
    reference: '*iteration:3061',
  },
  {
    id: 3086,
    title: 'Enim beatae voluptatem facilis excepturi culpa quae in. Nov 13, 2024 - Dec 10, 2024',
    reference: '*iteration:3086',
  },
];

export const MOCK_VULNERABILITIES = [
  {
    id: 99499903,
    title: 'Cross Site Scripting (Persistent)',
  },
  {
    id: 99495085,
    title: 'Possible SQL injection',
  },
  {
    id: 99490610,
    title: 'GitLab Runner Authentication Token',
  },
  {
    id: 99288920,
    title: 'Cross Site Scripting (Persistent)',
  },
  {
    id: 99258720,
    title: 'Cross Site Scripting (Persistent)',
  },
];

export const MOCK_COMMANDS = [
  {
    name: 'due',
    aliases: [],
    description: 'Set due date',
    warning: '',
    icon: '',
    params: ['\u003cin 2 days | this Friday | December 31st\u003e'],
  },
  {
    name: 'duplicate',
    aliases: [],
    description: 'Mark this issue as a duplicate of another issue',
    warning: '',
    icon: '',
    params: ['#issue'],
  },
  {
    name: 'clone',
    aliases: [],
    description: 'Clone this issue',
    warning: '',
    icon: '',
    params: ['path/to/project [--with_notes]'],
  },
  {
    name: 'move',
    aliases: [],
    description: 'Move this issue to another project.',
    warning: '',
    icon: '',
    params: ['path/to/project'],
  },
  {
    name: 'create_merge_request',
    aliases: [],
    description: 'Create a merge request',
    warning: '',
    icon: '',
    params: ['\u003cbranch name\u003e'],
  },
  {
    name: 'zoom',
    aliases: [],
    description: 'Add Zoom meeting',
    warning: '',
    icon: '',
    params: ['\u003cZoom URL\u003e'],
  },
  {
    name: 'promote_to_incident',
    aliases: [],
    description: 'Promote issue to incident',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'close',
    aliases: [],
    description: 'Close this issue',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'title',
    aliases: [],
    description: 'Change title',
    warning: '',
    icon: '',
    params: ['\u003cNew title\u003e'],
  },
  {
    name: 'label',
    aliases: ['labels'],
    description: 'Add labels',
    warning: '',
    icon: '',
    params: ['~label1 ~"label 2"'],
  },
  {
    name: 'unlabel',
    aliases: ['remove_label'],
    description: 'Remove all or specific labels',
    warning: '',
    icon: '',
    params: ['~label1 ~"label 2"'],
  },
  {
    name: 'relabel',
    aliases: [],
    description: 'Replace all labels',
    warning: '',
    icon: '',
    params: ['~label1 ~"label 2"'],
  },
  {
    name: 'todo',
    aliases: [],
    description: 'Add a to-do item',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'unsubscribe',
    aliases: [],
    description: 'Unsubscribe',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'award',
    aliases: [],
    description: 'Toggle emoji award',
    warning: '',
    icon: '',
    params: [':emoji:'],
  },
  {
    name: 'shrug',
    aliases: [],
    description: 'Append the comment with ¯\\＿(ツ)＿/¯',
    warning: '',
    icon: '',
    params: ['\u003cComment\u003e'],
  },
  {
    name: 'tableflip',
    aliases: [],
    description: 'Append the comment with (╯°□°)╯︵ ┻━┻',
    warning: '',
    icon: '',
    params: ['\u003cComment\u003e'],
  },
  {
    name: 'confidential',
    aliases: [],
    description: 'Make issue confidential',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'assign',
    aliases: [],
    description: 'Assign',
    warning: '',
    icon: '',
    params: ['@user1 @user2'],
  },
  {
    name: 'unassign',
    aliases: [],
    description: 'Remove all or specific assignees',
    warning: '',
    icon: '',
    params: ['@user1 @user2'],
  },
  {
    name: 'milestone',
    aliases: [],
    description: 'Set milestone',
    warning: '',
    icon: '',
    params: ['%"milestone"'],
  },
  {
    name: 'remove_milestone',
    aliases: [],
    description: 'Remove milestone',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'copy_metadata',
    aliases: [],
    description: 'Copy labels and milestone from other issue or merge request in this project',
    warning: '',
    icon: '',
    params: ['#issue | !merge_request'],
  },
  {
    name: 'estimate',
    aliases: ['estimate_time'],
    description: 'Set time estimate',
    warning: '',
    icon: '',
    params: ['\u003c1w 3d 2h 14m\u003e'],
  },
  {
    name: 'spend',
    aliases: ['spent', 'spend_time'],
    description: 'Add or subtract spent time',
    warning: '',
    icon: '',
    params: ['\u003ctime(1h30m | -1h30m)\u003e \u003cdate(YYYY-MM-DD)\u003e'],
  },
  {
    name: 'remove_estimate',
    aliases: ['remove_time_estimate'],
    description: 'Remove time estimate',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'remove_time_spent',
    aliases: [],
    description: 'Remove spent time',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'lock',
    aliases: [],
    description: 'Lock the discussion',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'cc',
    aliases: [],
    description: 'CC',
    warning: '',
    icon: '',
    params: ['@user'],
  },
  {
    name: 'relate',
    aliases: [],
    description: 'Mark this issue as related to another issue',
    warning: '',
    icon: '',
    params: ['\u003c#issue | group/project#issue | issue URL\u003e'],
  },
  {
    name: 'unlink',
    aliases: [],
    description: 'Remove link with another issue',
    warning: '',
    icon: '',
    params: ['\u003c#issue | group/project#issue | issue URL\u003e'],
  },
  {
    name: 'epic',
    aliases: [],
    description: 'Add to epic',
    warning: '',
    icon: '',
    params: ['\u003c\u0026epic | group\u0026epic | Epic URL\u003e'],
  },
  {
    name: 'remove_epic',
    aliases: [],
    description: 'Remove from epic',
    warning: '',
    icon: '',
    params: [],
  },
  {
    name: 'promote',
    aliases: [],
    description: 'Promote issue to an epic',
    warning: '',
    icon: 'confidential',
    params: [],
  },
  {
    name: 'iteration',
    aliases: [],
    description: 'Set iteration',
    warning: '',
    icon: '',
    params: ['*iteration:"iteration name" | *iteration:\u003cID\u003e'],
  },
  {
    name: 'health_status',
    aliases: [],
    description: 'Set health status',
    warning: '',
    icon: '',
    params: ['\u003con_track|needs_attention|at_risk\u003e'],
  },
  {
    name: 'reassign',
    aliases: [],
    description: 'Change assignees',
    warning: '',
    icon: '',
    params: ['@user1 @user2'],
  },
  {
    name: 'weight',
    aliases: [],
    description: 'Set weight',
    warning: '',
    icon: '',
    params: ['0, 1, 2, …'],
  },
  {
    name: 'blocks',
    aliases: [],
    description: 'Specifies that this issue blocks other issues',
    warning: '',
    icon: '',
    params: ['\u003c#issue | group/project#issue | issue URL\u003e'],
  },
  {
    name: 'blocked_by',
    aliases: [],
    description: 'Mark this issue as blocked by other issues',
    warning: '',
    icon: '',
    params: ['\u003c#issue | group/project#issue | issue URL\u003e'],
  },
];

export const MOCK_WIKIS = [
  {
    title: 'Home',
    slug: 'home',
    path: '/gitlab-org/gitlab-test/-/wikis/home',
  },
  {
    title: 'How to use GitLab',
    slug: 'how-to-use-gitlab',
    path: '/gitlab-org/gitlab-test/-/wikis/how-to-use-gitlab',
  },
  {
    title: 'Changelog',
    slug: 'changelog',
    path: '/gitlab-org/gitlab-test/-/wikis/changelog',
  },
];

export const MOCK_NEW_MEMBERS = [
  {
    type: 'User',
    username: 'walker.finn',
    name: 'Finneas Walker',
    avatar_url:
      'https://www.gravatar.com/avatar/ac82b5615d3308ecbcacedad361af8e7?s=80\u0026d=identicon',
    availability: null,
  },
];
