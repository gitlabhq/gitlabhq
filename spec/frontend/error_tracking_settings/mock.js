import { TEST_HOST } from 'helpers/test_constants';
import createStore from '~/error_tracking_settings/store';

const defaultStore = createStore();

export const projectList = [
  {
    name: 'name',
    slug: 'slug',
    organizationName: 'organizationName',
    organizationSlug: 'organizationSlug',
  },
  {
    name: 'name2',
    slug: 'slug2',
    organizationName: 'organizationName2',
    organizationSlug: 'organizationSlug2',
  },
];

export const staleProject = {
  name: 'staleName',
  slug: 'staleSlug',
  organizationName: 'staleOrganizationName',
  organizationSlug: 'staleOrganizationSlug',
};

export const normalizedProject = {
  name: 'name',
  slug: 'slug',
  organizationName: 'organization_name',
  organizationSlug: 'organization_slug',
};

export const sampleBackendProject = {
  name: normalizedProject.name,
  slug: normalizedProject.slug,
  organization_name: normalizedProject.organizationName,
  organization_slug: normalizedProject.organizationSlug,
};

export const sampleFrontendSettings = {
  apiHost: 'apiHost',
  enabled: false,
  token: 'token',
  selectedProject: {
    slug: normalizedProject.slug,
    name: normalizedProject.name,
    organizationName: normalizedProject.organizationName,
    organizationSlug: normalizedProject.organizationSlug,
  },
};

export const transformedSettings = {
  api_host: 'apiHost',
  enabled: false,
  token: 'token',
  project: {
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
  project: null,
  token: '',
  listProjectsEndpoint: TEST_HOST,
  operationsSettingsEndpoint: TEST_HOST,
};

export const initialPopulatedState = {
  apiHost: 'apiHost',
  enabled: true,
  project: JSON.stringify(projectList[0]),
  token: 'token',
  listProjectsEndpoint: TEST_HOST,
  operationsSettingsEndpoint: TEST_HOST,
};

export const projectWithHtmlTemplate = {
  ...projectList[0],
  name: '<strong>bold</strong>',
};
