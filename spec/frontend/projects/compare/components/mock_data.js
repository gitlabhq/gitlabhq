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
