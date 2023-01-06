import { TEST_HOST } from 'helpers/test_constants';
import createStore from '~/error_tracking_settings/store';

const defaultStore = createStore();

export const projectList = [
  {
    id: '1',
    name: 'name',
    slug: 'slug',
    organizationName: 'organizationName',
    organizationSlug: 'organizationSlug',
  },
  {
    id: '2',
    name: 'name2',
    slug: 'slug2',
    organizationName: 'organizationName2',
    organizationSlug: 'organizationSlug2',
  },
];

export const staleProject = {
  id: '3',
  name: 'staleName',
  slug: 'staleSlug',
  organizationName: 'staleOrganizationName',
  organizationSlug: 'staleOrganizationSlug',
};

export const normalizedProject = {
  id: '5',
  name: 'name',
  slug: 'slug',
  organizationName: 'organization_name',
  organizationSlug: 'organization_slug',
};

export const sampleBackendProject = {
  id: '5',
  name: normalizedProject.name,
  slug: normalizedProject.slug,
  organization_name: normalizedProject.organizationName,
  organization_slug: normalizedProject.organizationSlug,
};

export const sampleFrontendSettings = {
  apiHost: 'apiHost',
  enabled: false,
  integrated: false,
  token: 'token',
  selectedProject: {
    id: '5',
    slug: normalizedProject.slug,
    name: normalizedProject.name,
    organizationName: normalizedProject.organizationName,
    organizationSlug: normalizedProject.organizationSlug,
  },
};

export const transformedSettings = {
  api_host: 'apiHost',
  enabled: false,
  integrated: false,
  token: 'token',
  project: {
    sentry_project_id: '5',
    slug: normalizedProject.slug,
    name: normalizedProject.name,
    organization_name: normalizedProject.organizationName,
    organization_slug: normalizedProject.organizationSlug,
  },
};

export const defaultProps = {
  ...defaultStore.state,
  ...defaultStore.getters,
};

export const initialEmptyState = {
  apiHost: '',
  enabled: false,
  integrated: false,
  project: null,
  token: '',
  listProjectsEndpoint: TEST_HOST,
  operationsSettingsEndpoint: TEST_HOST,
};

export const initialPopulatedState = {
  apiHost: 'apiHost',
  enabled: true,
  integrated: true,
  project: JSON.stringify(projectList[0]),
  token: 'token',
  listProjectsEndpoint: TEST_HOST,
  operationsSettingsEndpoint: TEST_HOST,
};

export const projectWithHtmlTemplate = {
  ...projectList[0],
  name: '<strong>bold</strong>',
};
