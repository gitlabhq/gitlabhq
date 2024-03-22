import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY } from '~/search/store/constants';
import * as types from '~/search/store/mutation_types';

export const MOCK_QUERY = {
  scope: 'issues',
  state: 'all',
  confidential: null,
  group_id: 1,
  language: ['C', 'JavaScript'],
  labels: ['60', '37'],
  search: '*',
};

export const MOCK_GROUP = {
  id: 1,
  name: 'test group',
  full_name: 'full name / test group',
};

export const MOCK_GROUPS = [
  {
    id: 1,
    avatar_url: null,
    name: 'test group',
    full_name: 'full name / test group',
  },
  {
    id: 2,
    avatar_url: 'https://avatar.com',
    name: 'test group 2',
    full_name: 'full name / test group 2',
  },
];

export const MOCK_PROJECT = {
  id: 1,
  name: 'test project',
  namespace: MOCK_GROUP,
  nameWithNamespace: 'test group / test project',
};

export const MOCK_PROJECTS = [
  {
    id: 1,
    name: 'test project',
    namespace: MOCK_GROUP,
    name_with_namespace: 'test group / test project',
  },
  {
    id: 2,
    name: 'test project 2',
    namespace: MOCK_GROUP,
    name_with_namespace: 'test group / test project 2',
  },
];

export const MOCK_SORT_OPTIONS = [
  {
    title: 'Most relevant',
    sortable: false,
    sortParam: 'relevant',
  },
  {
    title: 'Created date',
    sortable: true,
    sortParam: {
      asc: 'created_asc',
      desc: 'created_desc',
    },
  },
];

export const MOCK_LS_KEY = 'mock-ls-key';

export const MOCK_INFLATED_DATA = [
  { id: 1, name: 'test 1' },
  { id: 2, name: 'test 2' },
];

export const FRESH_STORED_DATA = [
  { id: 1, name: 'test 1', frequency: 1 },
  { id: 2, name: 'test 2', frequency: 2 },
];

export const STALE_STORED_DATA = [
  { id: 1, name: 'blah 1', frequency: 1 },
  { id: 2, name: 'blah 2', frequency: 2 },
];

export const MOCK_FRESH_DATA_RES = { name: 'fresh' };

export const PRELOAD_EXPECTED_MUTATIONS = [
  {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: GROUPS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
  },
  {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: PROJECTS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
  },
];

export const PROMISE_ALL_EXPECTED_MUTATIONS = {
  resGroups: {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: GROUPS_LOCAL_STORAGE_KEY, data: [MOCK_FRESH_DATA_RES, MOCK_FRESH_DATA_RES] },
  },
  resProjects: {
    type: types.LOAD_FREQUENT_ITEMS,
    payload: { key: PROJECTS_LOCAL_STORAGE_KEY, data: [MOCK_FRESH_DATA_RES, MOCK_FRESH_DATA_RES] },
  },
};

export const MOCK_NAVIGATION = {
  projects: {
    label: 'Projects',
    scope: 'projects',
    link: '/search?scope=projects&search=et',
    count_link: '/search/count?scope=projects&search=et',
    count: '10,000+',
  },
  blobs: {
    label: 'Code',
    scope: 'blobs',
    link: '/search?scope=blobs&search=et',
    count_link: '/search/count?scope=blobs&search=et',
  },
  issues: {
    label: 'Issues',
    scope: 'issues',
    link: '/search?scope=issues&search=et',
    active: true,
    count: '2,430',
  },
  epics: {
    label: 'Epics',
    scope: 'epics',
    link: '/search?scope=epics&search=et',
    active: true,
    count: '0',
  },
  merge_requests: {
    label: 'Merge requests',
    scope: 'merge_requests',
    link: '/search?scope=merge_requests&search=et',
    count_link: '/search/count?scope=merge_requests&search=et',
  },
  wiki_blobs: {
    label: 'Wiki',
    scope: 'wiki_blobs',
    link: '/search?scope=wiki_blobs&search=et',
    count_link: '/search/count?scope=wiki_blobs&search=et',
  },
  commits: {
    label: 'Commits',
    scope: 'commits',
    link: '/search?scope=commits&search=et',
    count_link: '/search/count?scope=commits&search=et',
  },
  notes: {
    label: 'Comments',
    scope: 'notes',
    link: '/search?scope=notes&search=et',
    count_link: '/search/count?scope=notes&search=et',
  },
  milestones: {
    label: 'Milestones',
    scope: 'milestones',
    link: '/search?scope=milestones&search=et',
    count_link: '/search/count?scope=milestones&search=et',
  },
  users: {
    label: 'Users',
    scope: 'users',
    link: '/search?scope=users&search=et',
    count_link: '/search/count?scope=users&search=et',
  },
};

export const MOCK_NAVIGATION_DATA = {
  projects: {
    label: 'Projects',
    scope: 'projects',
    link: '/search?scope=projects&search=et',
    count_link: '/search/count?scope=projects&search=et',
  },
};

export const MOCK_ENDPOINT_RESPONSE = { count: '13' };

export const MOCK_DATA_FOR_NAVIGATION_ACTION_MUTATION = {
  projects: {
    count: '13',
    label: 'Projects',
    scope: 'projects',
    link: '/search?scope=projects&search=et',
    count_link: null,
  },
};

export const MOCK_NAVIGATION_ACTION_MUTATION = {
  type: types.RECEIVE_NAVIGATION_COUNT,
  payload: { key: 'projects', count: '13' },
};

export const MOCK_LANGUAGE_AGGREGATIONS_BUCKETS = [
  { key: 'random-label-edumingos0', count: 1 },
  { key: 'random-label-rbourgourd1', count: 2 },
  { key: 'random-label-dfearnside2', count: 3 },
  { key: 'random-label-gewins3', count: 4 },
  { key: 'random-label-telverstone4', count: 5 },
  { key: 'random-label-ygerriets5', count: 6 },
  { key: 'random-label-lmoffet6', count: 7 },
  { key: 'random-label-ehinnerk7', count: 8 },
  { key: 'random-label-flanceley8', count: 9 },
  { key: 'random-label-adoyle9', count: 10 },
  { key: 'random-label-rmcgirla', count: 11 },
  { key: 'random-label-dwhellansb', count: 12 },
  { key: 'random-label-apitkethlyc', count: 13 },
  { key: 'random-label-senevoldsend', count: 14 },
  { key: 'random-label-tlardnare', count: 15 },
  { key: 'random-label-fcoilsf', count: 16 },
  { key: 'random-label-qgeckg', count: 17 },
  { key: 'random-label-rgrabenh', count: 18 },
  { key: 'random-label-lashardi', count: 19 },
  { key: 'random-label-sadamovitchj', count: 20 },
  { key: 'random-label-rlyddiardk', count: 21 },
  { key: 'random-label-jpoell', count: 22 },
  { key: 'random-label-kcharitym', count: 23 },
  { key: 'random-label-cbertenshawn', count: 24 },
  { key: 'random-label-jsturgeso', count: 25 },
  { key: 'random-label-ohouldcroftp', count: 26 },
  { key: 'random-label-rheijnenq', count: 27 },
  { key: 'random-label-snortheyr', count: 28 },
  { key: 'random-label-vpairpoints', count: 29 },
  { key: 'random-label-odavidovicit', count: 30 },
  { key: 'random-label-fmccartu', count: 31 },
  { key: 'random-label-cwansburyv', count: 32 },
  { key: 'random-label-bdimontw', count: 33 },
  { key: 'random-label-adocketx', count: 34 },
  { key: 'random-label-obavridgey', count: 35 },
  { key: 'random-label-jperezz', count: 36 },
  { key: 'random-label-gdeneve10', count: 37 },
  { key: 'random-label-rmckeand11', count: 38 },
  { key: 'random-label-kwestmerland12', count: 39 },
  { key: 'random-label-mpryer13', count: 40 },
  { key: 'random-label-rmcneil14', count: 41 },
  { key: 'random-label-ablondel15', count: 42 },
  { key: 'random-label-wbalducci16', count: 43 },
  { key: 'random-label-swigley17', count: 44 },
  { key: 'random-label-gferroni18', count: 45 },
  { key: 'random-label-icollings19', count: 46 },
  { key: 'random-label-wszymanski1a', count: 47 },
  { key: 'random-label-jelson1b', count: 48 },
  { key: 'random-label-fsambrook1c', count: 49 },
  { key: 'random-label-kconey1d', count: 50 },
  { key: 'random-label-agoodread1e', count: 51 },
  { key: 'random-label-nmewton1f', count: 52 },
  { key: 'random-label-gcodman1g', count: 53 },
  { key: 'random-label-rpoplee1h', count: 54 },
  { key: 'random-label-mhug1i', count: 55 },
  { key: 'random-label-ggowrie1j', count: 56 },
  { key: 'random-label-ctonepohl1k', count: 57 },
  { key: 'random-label-cstillman1l', count: 58 },
  { key: 'random-label-dcollyer1m', count: 59 },
  { key: 'random-label-idimelow1n', count: 60 },
  { key: 'random-label-djarley1o', count: 61 },
  { key: 'random-label-omclleese1p', count: 62 },
  { key: 'random-label-dstivers1q', count: 63 },
  { key: 'random-label-svose1r', count: 64 },
  { key: 'random-label-clanfare1s', count: 65 },
  { key: 'random-label-aport1t', count: 66 },
  { key: 'random-label-hcarlett1u', count: 67 },
  { key: 'random-label-dstillmann1v', count: 68 },
  { key: 'random-label-ncorpe1w', count: 69 },
  { key: 'random-label-mjacobsohn1x', count: 70 },
  { key: 'random-label-ycleiment1y', count: 71 },
  { key: 'random-label-owherton1z', count: 72 },
  { key: 'random-label-anowaczyk20', count: 73 },
  { key: 'random-label-rmckennan21', count: 74 },
  { key: 'random-label-cmoulding22', count: 75 },
  { key: 'random-label-sswate23', count: 76 },
  { key: 'random-label-cbarge24', count: 77 },
  { key: 'random-label-agrainger25', count: 78 },
  { key: 'random-label-ncosin26', count: 79 },
  { key: 'random-label-pkears27', count: 80 },
  { key: 'random-label-cmcarthur28', count: 81 },
  { key: 'random-label-jmantripp29', count: 82 },
  { key: 'random-label-cjekel2a', count: 83 },
  { key: 'random-label-hdilleway2b', count: 84 },
  { key: 'random-label-lbovaird2c', count: 85 },
  { key: 'random-label-mweld2d', count: 86 },
  { key: 'random-label-marnowitz2e', count: 87 },
  { key: 'random-label-nbertomieu2f', count: 88 },
  { key: 'random-label-mledward2g', count: 89 },
  { key: 'random-label-mhince2h', count: 90 },
  { key: 'random-label-baarons2i', count: 91 },
  { key: 'random-label-kfrancie2j', count: 92 },
  { key: 'random-label-ishooter2k', count: 93 },
  { key: 'random-label-glowmass2l', count: 94 },
  { key: 'random-label-rgeorgi2m', count: 95 },
  { key: 'random-label-bproby2n', count: 96 },
  { key: 'random-label-hsteffan2o', count: 97 },
  { key: 'random-label-doruane2p', count: 98 },
  { key: 'random-label-rlunny2q', count: 99 },
  { key: 'random-label-geles2r', count: 100 },
  { key: 'random-label-nmaggiore2s', count: 101 },
  { key: 'random-label-aboocock2t', count: 102 },
  { key: 'random-label-eguilbert2u', count: 103 },
  { key: 'random-label-emccutcheon2v', count: 104 },
  { key: 'random-label-hcowser2w', count: 105 },
  { key: 'random-label-dspeeding2x', count: 106 },
  { key: 'random-label-oseebright2y', count: 107 },
  { key: 'random-label-hpresdee2z', count: 108 },
  { key: 'random-label-pesseby30', count: 109 },
  { key: 'random-label-hpusey31', count: 110 },
  { key: 'random-label-dmanthorpe32', count: 111 },
  { key: 'random-label-natley33', count: 112 },
  { key: 'random-label-iferentz34', count: 113 },
  { key: 'random-label-adyble35', count: 114 },
  { key: 'random-label-dlockitt36', count: 115 },
  { key: 'random-label-acoxwell37', count: 116 },
  { key: 'random-label-amcgarvey38', count: 117 },
  { key: 'random-label-rmcgougan39', count: 118 },
  { key: 'random-label-mscole3a', count: 119 },
  { key: 'random-label-lmalim3b', count: 120 },
  { key: 'random-label-cends3c', count: 121 },
  { key: 'random-label-dmannie3d', count: 122 },
  { key: 'random-label-lgoodricke3e', count: 123 },
  { key: 'random-label-rcaghy3f', count: 124 },
  { key: 'random-label-mprozillo3g', count: 125 },
  { key: 'random-label-mcardnell3h', count: 126 },
  { key: 'random-label-gericssen3i', count: 127 },
  { key: 'random-label-fspooner3j', count: 128 },
  { key: 'random-label-achadney3k', count: 129 },
  { key: 'random-label-corchard3l', count: 130 },
  { key: 'random-label-lyerill3m', count: 131 },
  { key: 'random-label-jrusk3n', count: 132 },
  { key: 'random-label-lbonelle3o', count: 133 },
  { key: 'random-label-eduny3p', count: 134 },
  { key: 'random-label-mhutchence3q', count: 135 },
  { key: 'random-label-rmargeram3r', count: 136 },
  { key: 'random-label-smaudlin3s', count: 137 },
  { key: 'random-label-sfarrance3t', count: 138 },
  { key: 'random-label-eclendennen3u', count: 139 },
  { key: 'random-label-cyabsley3v', count: 140 },
  { key: 'random-label-ahensmans3w', count: 141 },
  { key: 'random-label-tsenchenko3x', count: 142 },
  { key: 'random-label-ryurchishin3y', count: 143 },
  { key: 'random-label-teby3z', count: 144 },
  { key: 'random-label-dvaillant40', count: 145 },
  { key: 'random-label-kpetyakov41', count: 146 },
  { key: 'random-label-cmorrison42', count: 147 },
  { key: 'random-label-ltwiddy43', count: 148 },
  { key: 'random-label-ineame44', count: 149 },
  { key: 'random-label-blucock45', count: 150 },
  { key: 'random-label-kdunsford46', count: 151 },
  { key: 'random-label-dducham47', count: 152 },
  { key: 'random-label-javramovitz48', count: 153 },
  { key: 'random-label-mascraft49', count: 154 },
  { key: 'random-label-bloughead4a', count: 155 },
  { key: 'random-label-sduckit4b', count: 156 },
  { key: 'random-label-hhardman4c', count: 157 },
  { key: 'random-label-cstaniforth4d', count: 158 },
  { key: 'random-label-jedney4e', count: 159 },
  { key: 'random-label-bobbard4f', count: 160 },
  { key: 'random-label-cgiraux4g', count: 161 },
  { key: 'random-label-tkiln4h', count: 162 },
  { key: 'random-label-jwansbury4i', count: 163 },
  { key: 'random-label-dquinlan4j', count: 164 },
  { key: 'random-label-hgindghill4k', count: 165 },
  { key: 'random-label-jjowle4l', count: 166 },
  { key: 'random-label-egambrell4m', count: 167 },
  { key: 'random-label-jmcgloughlin4n', count: 168 },
  { key: 'random-label-bbabb4o', count: 169 },
  { key: 'random-label-achuck4p', count: 170 },
  { key: 'random-label-tsyers4q', count: 171 },
  { key: 'random-label-jlandon4r', count: 172 },
  { key: 'random-label-wteather4s', count: 173 },
  { key: 'random-label-dfoskin4t', count: 174 },
  { key: 'random-label-gmorlon4u', count: 175 },
  { key: 'random-label-jseely4v', count: 176 },
  { key: 'random-label-cbrass4w', count: 177 },
  { key: 'random-label-fmanilo4x', count: 178 },
  { key: 'random-label-bfrangleton4y', count: 179 },
  { key: 'random-label-vbartkiewicz4z', count: 180 },
  { key: 'random-label-tclymer50', count: 181 },
  { key: 'random-label-pqueen51', count: 182 },
  { key: 'random-label-bpol52', count: 183 },
  { key: 'random-label-jclaeskens53', count: 184 },
  { key: 'random-label-cstranieri54', count: 185 },
  { key: 'random-label-drumbelow55', count: 186 },
  { key: 'random-label-wbrumham56', count: 187 },
  { key: 'random-label-azeal57', count: 188 },
  { key: 'random-label-msnooks58', count: 189 },
  { key: 'random-label-blapre59', count: 190 },
  { key: 'random-label-cduckers5a', count: 191 },
  { key: 'random-label-mgumary5b', count: 192 },
  { key: 'random-label-rtebbs5c', count: 193 },
  { key: 'random-label-eroe5d', count: 194 },
  { key: 'random-label-rconfait5e', count: 195 },
  { key: 'random-label-fsinderland5f', count: 196 },
  { key: 'random-label-tdallywater5g', count: 197 },
  { key: 'random-label-glindenman5h', count: 198 },
  { key: 'random-label-fbauser5i', count: 199 },
  { key: 'random-label-bdownton5j', count: 200 },
];

export const MOCK_AGGREGATIONS = [
  {
    name: 'language',
    buckets: MOCK_LANGUAGE_AGGREGATIONS_BUCKETS,
  },
];

export const SORTED_MOCK_AGGREGATIONS = [
  {
    name: 'language',
    buckets: MOCK_LANGUAGE_AGGREGATIONS_BUCKETS.reverse(),
  },
];

export const MOCK_RECEIVE_AGGREGATIONS_SUCCESS_MUTATION = [
  {
    type: types.REQUEST_AGGREGATIONS,
  },
  {
    type: types.RECEIVE_AGGREGATIONS_SUCCESS,
    payload: SORTED_MOCK_AGGREGATIONS,
  },
];

export const MOCK_RECEIVE_AGGREGATIONS_ERROR_MUTATION = [
  {
    type: types.REQUEST_AGGREGATIONS,
  },
  {
    type: types.RECEIVE_AGGREGATIONS_ERROR,
  },
];

export const TEST_RAW_BUCKETS = [
  { key: 'Go', count: 350 },
  { key: 'C', count: 298 },
  { key: 'JavaScript', count: 128 },
  { key: 'YAML', count: 58 },
  { key: 'Text', count: 46 },
  { key: 'Markdown', count: 37 },
  { key: 'HTML', count: 34 },
  { key: 'Shell', count: 34 },
  { key: 'Makefile', count: 21 },
  { key: 'JSON', count: 15 },
];

export const TEST_FILTER_DATA = {
  header: 'Language',
  scopes: { BLOBS: 'blobs' },
  filterParam: 'language',
  filters: {
    GO: { label: 'Go', value: 'Go', count: 350 },
    C: { label: 'C', value: 'C', count: 298 },
    JAVASCRIPT: { label: 'JavaScript', value: 'JavaScript', count: 128 },
    YAML: { label: 'YAML', value: 'YAML', count: 58 },
    TEXT: { label: 'Text', value: 'Text', count: 46 },
    MARKDOWN: { label: 'Markdown', value: 'Markdown', count: 37 },
    HTML: { label: 'HTML', value: 'HTML', count: 34 },
    SHELL: { label: 'Shell', value: 'Shell', count: 34 },
    MAKEFILE: { label: 'Makefile', value: 'Makefile', count: 21 },
    JSON: { label: 'JSON', value: 'JSON', count: 15 },
  },
};

export const SMALL_MOCK_AGGREGATIONS = [
  {
    name: 'language',
    buckets: TEST_RAW_BUCKETS,
  },
];

export const MOCK_NAVIGATION_ITEMS = [
  {
    title: 'Projects',
    icon: 'project',
    link: '/search?scope=projects&search=et',
    is_active: false,
    pill_count: '10K+',
    items: [],
  },
  {
    title: 'Code',
    icon: 'code',
    link: '/search?scope=blobs&search=et',
    is_active: false,
    pill_count: '0',
    items: [],
  },
  {
    title: 'Issues',
    icon: 'issues',
    link: '/search?scope=issues&search=et',
    is_active: true,
    pill_count: '2.4K',
    items: [],
  },
  {
    title: 'Epics',
    icon: 'epic',
    link: '/search?scope=epics&search=et',
    is_active: true,
    pill_count: '0',
    items: [],
  },
  {
    title: 'Merge requests',
    icon: 'merge-request',
    link: '/search?scope=merge_requests&search=et',
    is_active: false,
    pill_count: '0',
    items: [],
  },
  {
    title: 'Wiki',
    icon: 'book',
    link: '/search?scope=wiki_blobs&search=et',
    is_active: false,
    pill_count: '0',
    items: [],
  },
  {
    title: 'Commits',
    icon: 'commit',
    link: '/search?scope=commits&search=et',
    is_active: false,
    pill_count: '0',
    items: [],
  },
  {
    title: 'Comments',
    icon: 'comments',
    link: '/search?scope=notes&search=et',
    is_active: false,
    pill_count: '0',
    items: [],
  },
  {
    title: 'Milestones',
    icon: 'milestone',
    link: '/search?scope=milestones&search=et',
    is_active: false,
    pill_count: '0',
    items: [],
  },
  {
    title: 'Users',
    icon: 'users',
    link: '/search?scope=users&search=et',
    is_active: false,
    pill_count: '0',
    items: [],
  },
];

export const PROCESS_LABELS_DATA = [
  {
    key: '60',
    count: 14,
    title: 'Brist',
    color: 'rgb(170, 174, 187)',
    type: 'GroupLabel',
    parent_full_name: 'Twitter',
  },
  {
    key: '69',
    count: 13,
    title: 'Brouneforge',
    color: 'rgb(170, 174, 187)',
    type: 'GroupLabel',
    parent_full_name: 'Twitter',
  },
  {
    key: '33',
    count: 12,
    title: 'Brifunc',
    color: 'rgb(170, 174, 187)',
    type: 'GroupLabel',
    parent_full_name: 'Commit451',
  },
  {
    key: '37',
    count: 12,
    title: 'Aftersync',
    color: 'rgb(170, 174, 187)',
    type: 'GroupLabel',
    parent_full_name: 'Commit451',
  },
];

export const APPLIED_SELECTED_LABELS = [
  {
    key: '60',
    count: 14,
    title: 'Brist',
    color: '#aaaebb',
    type: 'GroupLabel',
    parent_full_name: 'Twitter',
  },
  {
    key: '37',
    count: 12,
    title: 'Aftersync',
    color: '#79fdbf',
    type: 'GroupLabel',
    parent_full_name: 'Commit451',
  },
];

export const MOCK_LABEL_AGGREGATIONS = {
  fetching: false,
  error: false,
  data: [
    {
      name: 'labels',
      buckets: [
        {
          key: '60',
          count: 14,
          title: 'Brist',
          color: '#aaaebb',
          type: 'GroupLabel',
          parent_full_name: 'Twitter',
        },
        {
          key: '37',
          count: 12,
          title: 'Aftersync',
          color: '#79fdbf',
          type: 'GroupLabel',
          parent_full_name: 'Commit451',
        },
        {
          key: '6',
          count: 12,
          title: 'Cosche',
          color: '#cea786',
          type: 'GroupLabel',
          parent_full_name: 'Toolbox',
        },
        {
          key: '73',
          count: 12,
          title: 'Accent',
          color: '#a5c6fb',
          type: 'ProjectLabel',
          parent_full_name: 'Toolbox / Gitlab Smoke Tests',
        },
      ],
    },
  ],
};

export const MOCK_LABEL_SEARCH_RESULT = {
  key: '37',
  count: 12,
  title: 'Aftersync',
  color: '#79fdbf',
  type: 'GroupLabel',
  parent_full_name: 'Commit451',
};

export const MOCK_FILTERED_UNSELECTED_LABELS = [
  {
    key: '6',
    count: 12,
    title: 'Cosche',
    color: '#cea786',
    type: 'GroupLabel',
    parent_full_name: 'Toolbox',
  },
  {
    key: '73',
    count: 12,
    title: 'Accent',
    color: '#a5c6fb',
    type: 'ProjectLabel',
    parent_full_name: 'Toolbox / Gitlab Smoke Tests',
  },
];

export const MOCK_FILTERED_APPLIED_SELECTED_LABELS = [
  {
    key: '60',
    count: 14,
    title: 'Brist',
    color: '#aaaebb',
    type: 'GroupLabel',
    parent_full_name: 'Twitter',
  },
  {
    key: '37',
    count: 12,
    title: 'Aftersync',
    color: '#79fdbf',
    type: 'GroupLabel',
    parent_full_name: 'Commit451',
  },
];

export const MOCK_FILTERED_LABELS = [
  {
    key: '60',
    count: 14,
    title: 'Brist',
    color: '#aaaebb',
    type: 'GroupLabel',
    parent_full_name: 'Twitter',
  },
  {
    key: '69',
    count: 13,
    title: 'Brouneforge',
    color: '#8a13d3',
    type: 'GroupLabel',
    parent_full_name: 'Twitter',
  },
  {
    key: '33',
    count: 12,
    title: 'Brifunc',
    color: '#b76463',
    type: 'GroupLabel',
    parent_full_name: 'Commit451',
  },
  {
    key: '37',
    count: 12,
    title: 'Aftersync',
    color: '#79fdbf',
    type: 'GroupLabel',
    parent_full_name: 'Commit451',
  },
  {
    key: '6',
    count: 12,
    title: 'Cosche',
    color: '#cea786',
    type: 'GroupLabel',
    parent_full_name: 'Toolbox',
  },
  {
    key: '73',
    count: 12,
    title: 'Accent',
    color: '#a5c6fb',
    type: 'ProjectLabel',
    parent_full_name: 'Toolbox / Gitlab Smoke Tests',
  },
  {
    key: '9',
    count: 12,
    title: 'Briph',
    color: '#e69182',
    type: 'GroupLabel',
    parent_full_name: 'Toolbox',
  },
  {
    key: '91',
    count: 12,
    title: 'Cobalt',
    color: '#9eae75',
    type: 'ProjectLabel',
    parent_full_name: 'Commit451 / Lab Coat',
  },
  {
    key: '94',
    count: 12,
    title: 'Protege',
    color: '#777b83',
    type: 'ProjectLabel',
    parent_full_name: 'Commit451 / Lab Coat',
  },
  {
    key: '84',
    count: 11,
    title: 'Avenger',
    color: '#5c5161',
    type: 'ProjectLabel',
    parent_full_name: 'Gitlab Org / Gitlab Shell',
  },
  {
    key: '99',
    count: 11,
    title: 'Cobalt',
    color: '#9eae75',
    type: 'ProjectLabel',
    parent_full_name: 'Jashkenas / Underscore',
  },
  {
    key: '77',
    count: 10,
    title: 'Avenger',
    color: '#5c5161',
    type: 'ProjectLabel',
    parent_full_name: 'Gitlab Org / Gitlab Test',
  },
  {
    key: '79',
    count: 10,
    title: 'Fiero',
    color: '#681cd0',
    type: 'ProjectLabel',
    parent_full_name: 'Gitlab Org / Gitlab Test',
  },
  {
    key: '98',
    count: 9,
    title: 'Golf',
    color: '#007aaf',
    type: 'ProjectLabel',
    parent_full_name: 'Jashkenas / Underscore',
  },
  {
    key: '101',
    count: 7,
    title: 'Accord',
    color: '#a72b3b',
    type: 'ProjectLabel',
    parent_full_name: 'Flightjs / Flight',
  },
  {
    key: '53',
    count: 7,
    title: 'Amsche',
    color: '#9964cf',
    type: 'GroupLabel',
    parent_full_name: 'Flightjs',
  },
  {
    key: '11',
    count: 3,
    title: 'Aquasync',
    color: '#347e7f',
    type: 'GroupLabel',
    parent_full_name: 'Gitlab Org',
  },
  {
    key: '15',
    count: 3,
    title: 'Lunix',
    color: '#aad577',
    type: 'GroupLabel',
    parent_full_name: 'Gitlab Org',
  },
  {
    key: '88',
    count: 3,
    title: 'Aztek',
    color: '#59160a',
    type: 'ProjectLabel',
    parent_full_name: 'Gnuwget / Wget2',
  },
  {
    key: '89',
    count: 3,
    title: 'Intrigue',
    color: '#5039bd',
    type: 'ProjectLabel',
    parent_full_name: 'Gnuwget / Wget2',
  },
  {
    key: '96',
    count: 2,
    title: 'Trailblazer',
    color: '#5a3e93',
    type: 'ProjectLabel',
    parent_full_name: 'Jashkenas / Underscore',
  },
  {
    key: '54',
    count: 1,
    title: 'NB',
    color: '#a4a53a',
    type: 'GroupLabel',
    parent_full_name: 'Flightjs',
  },
];

export const CURRENT_SCOPE = 'blobs';
