const sourceProjectRefsPath = 'some/refs/path';
const targetProjectRefsPath = 'some/refs/path';
const paramsName = 'to';
const paramsBranch = 'main';
const sourceProject = {
  name: 'some-to-name',
  id: '2',
};
const targetProject = {
  name: 'some-to-name',
  id: '1',
};

export const appDefaultProps = {
  projectCompareIndexPath: 'some/path',
  projectMergeRequestPath: '',
  projects: [sourceProject],
  paramsFrom: 'main',
  paramsTo: 'target/branch',
  straight: false,
  createMrPath: '',
  sourceProjectRefsPath,
  targetProjectRefsPath,
  sourceProject,
  targetProject,
};

export const revisionCardDefaultProps = {
  selectedProject: targetProject,
  paramsBranch,
  revisionText: 'Source',
  refsProjectPath: sourceProjectRefsPath,
  paramsName,
};

export const repoDropdownDefaultProps = {
  selectedProject: targetProject,
  paramsName,
};

export const revisionDropdownDefaultProps = {
  refsProjectPath: sourceProjectRefsPath,
  paramsBranch,
  paramsName,
};

export const expectedTagsItems = [
  {
    options: [
      {
        text: 'tag-1',
        value: 'tag-1',
      },
      {
        text: 'tag-2',
        value: 'tag-2',
      },
      {
        text: 'tag-3',
        value: 'tag-3',
      },
    ],
    text: 'Tags',
  },
];

export const expectedBranchesItems = [
  {
    options: [
      {
        text: 'branch-1',
        value: 'branch-1',
      },
      {
        text: 'branch-2',
        value: 'branch-2',
      },
    ],
    text: 'Branches',
  },
];

export const expectedItems = [...expectedBranchesItems, ...expectedTagsItems];
