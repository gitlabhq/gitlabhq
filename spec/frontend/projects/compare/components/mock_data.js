const sourceProjectRefsPath = 'some/refs/path';
const targetProjectRefsPath = 'some/refs/path';
const paramsName = 'to';
const paramsBranch = 'main';
const sourceProject = {
  text: 'some-to-name',
  id: '2',
};

const targetProject = {
  text: 'some-to-name',
  id: '1',
};

const endpoint = '/flightjs/Flight/-/merge_requests/new/target_projects';

export const appDefaultProps = {
  projectCompareIndexPath: 'some/path',
  projectMergeRequestPath: '',
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
  endpoint,
};

export const repoDropdownDefaultProps = {
  selectedProject: targetProject,
  paramsName,
  endpoint,
};

export const revisionDropdownDefaultProps = {
  refsProjectPath: sourceProjectRefsPath,
  paramsBranch,
  paramsName,
};

export const targetProjects = [
  {
    id: 6,
    name: 'Flight',
    full_path: '/flightjs/Flight',
    full_name: 'Flightjs / Flight',
    refs_url: '/flightjs/Flight/refs',
  },
  {
    id: 11,
    name: 'Flight',
    full_path: '/rolando_kub/Flight',
    full_name: 'Kiersten Considine / Flight',
    refs_url: '/rolando_kub/Flight/refs',
  },
  {
    id: 12,
    name: 'Flight',
    full_path: '/janice.douglas/Flight',
    full_name: 'Jesse Hayes / Flight',
    refs_url: '/janice.douglas/Flight/refs',
  },
];
