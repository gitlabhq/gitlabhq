import {
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';
import { ACCESS_LEVEL_DEVELOPER_INTEGER } from '~/access_level/constants';
import { TIMESTAMP_TYPES } from '~/vue_shared/components/resource_lists/constants';
import ProjectsListItem from './projects_list_item.vue';

export default {
  component: ProjectsListItem,
  title: 'vue_shared/projects_list/projects-list-item',
  argTypes: {
    showProjectIcon: {
      control: 'boolean',
      description: 'Whether to show the project icon',
    },
    timestampType: {
      control: 'select',
      options: TIMESTAMP_TYPES,
      description: 'Type of timestamp to display',
    },
    includeMicrodata: {
      control: 'boolean',
      description: 'Whether to include microdata attributes',
    },
    listItemClass: {
      control: 'text',
      description: 'Additional classes to apply to the list item',
    },
  },
};

// Base project data
const baseProject = {
  id: 1,
  name: 'GitLab',
  nameWithNamespace: 'GitLab Org / GitLab',
  avatarLabel: 'GitLab Org / GitLab',
  fullPath: 'gitlab-org/gitlab',
  pathWithNamespace: 'gitlab-org/gitlab',
  relativeWebUrl: '/gitlab-org/gitlab',
  description:
    'GitLab Community Edition (CE) is an open source end-to-end software development platform.',
  visibility: VISIBILITY_LEVEL_PRIVATE_STRING,
  createdAt: '2022-01-15T10:30:00Z',
  updatedAt: '2024-01-15T14:20:00Z',
  lastActivityAt: '2024-01-15T16:45:00Z',
  starCount: 1250,
  forksCount: 890,
  openIssuesCount: 45,
  openMergeRequestsCount: 12,
  topics: ['ruby', 'vue', 'devops'],
  mergeRequestsAccessLevel: 'enabled',
  issuesAccessLevel: 'enabled',
  forkingAccessLevel: 'enabled',
  accessLevel: {
    integerValue: ACCESS_LEVEL_DEVELOPER_INTEGER,
  },
  statistics: {
    storageSize: 1024 * 1024 * 500, // 500MB
  },
  pipeline: {
    detailedStatus: {
      id: 'success-123',
      group: 'success',
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      detailsPath: '/gitlab-org/gitlab/-/pipelines/123',
    },
  },
  availableActions: [],
  isCatalogResource: false,
  isPublished: false,
  exploreCatalogPath: null,
};

const Template = (args, { argTypes }) => ({
  components: { ProjectsListItem },
  props: Object.keys(argTypes),
  template: `
    <ul class="gl-list-none gl-p-0">
      <projects-list-item v-bind="$props" />
    </ul>
  `,
});

export const Default = Template.bind({});
Default.args = {
  project: baseProject,
  showProjectIcon: false,
  timestampType: 'createdAt',
  includeMicrodata: false,
  listItemClass: '',
};

export const PublicProject = Template.bind({});
PublicProject.args = {
  ...Default.args,
  project: {
    ...baseProject,
    visibility: VISIBILITY_LEVEL_PUBLIC_STRING,
    name: 'Open Source Project',
    nameWithNamespace: 'Community / Open Source Project',
    avatarLabel: 'Community / Open Source Project',
    description: 'A popular open source project with high activity.',
    starCount: 15420,
    forksCount: 3890,
    topics: ['javascript', 'react', 'frontend'],
  },
};

export const CatalogProject = Template.bind({});
CatalogProject.args = {
  ...Default.args,
  project: {
    ...baseProject,
    name: 'CI Components Library',
    nameWithNamespace: 'DevOps / CI Components Library',
    avatarLabel: 'DevOps / CI Components Library',
    description: 'Reusable CI/CD components for GitLab pipelines.',
    isCatalogResource: true,
    isPublished: true,
    exploreCatalogPath: `/catalog/${baseProject.pathWithNamespace}`,
    topics: ['ci-cd', 'components', 'templates'],
  },
};

export const MinimalProject = Template.bind({});
MinimalProject.args = {
  ...Default.args,
  project: {
    ...baseProject,
    name: 'Simple Project',
    nameWithNamespace: 'User / Simple Project',
    avatarLabel: 'User / Simple Project',
    description: 'A simple project with minimal features.',
    starCount: 0,
    forksCount: 0,
    openIssuesCount: 0,
    openMergeRequestsCount: 0,
    topics: [],
    pipeline: null,
    statistics: null,
    availableActions: [],
  },
};
