import { GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectList from '~/usage_quotas/storage/namespace/components/project_list.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import StorageTypeHelpLink from '~/usage_quotas/storage/components/storage_type_help_link.vue';
import StorageTypeWarning from '~/usage_quotas/storage/components/storage_type_warning.vue';
import { storageTypeHelpPaths } from '~/usage_quotas/storage/constants';
import {
  mockGetNamespaceStorageGraphQLResponse,
  defaultNamespaceProvideValues,
  projectList,
  storageTypes,
} from '../../mock_data';

/** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
let wrapper;

const createComponent = ({ provide = {}, props = {} } = {}) => {
  wrapper = mountExtended(ProjectList, {
    provide: {
      ...defaultNamespaceProvideValues,
      ...provide,
    },
    propsData: {
      namespace: mockGetNamespaceStorageGraphQLResponse.data.namespace,
      projects: projectList,
      helpLinks: storageTypeHelpPaths,
      isLoading: false,
      sortBy: 'storage',
      enableSortableFields: false,
      ...props,
    },
  });
};

const findTable = () => wrapper.findComponent(GlTable);

describe('ProjectList', () => {
  describe('Table header', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each(storageTypes)('$key', ({ key }) => {
      const th = wrapper.findByTestId(`th-${key}`);
      const hasHelpLink = Boolean(storageTypeHelpPaths[key]);

      expect(th.findComponent(StorageTypeHelpLink).exists()).toBe(hasHelpLink);
    });

    it('shows warning icon for container registry type', () => {
      const storageTypeWarning = wrapper
        .findByTestId('th-containerRegistry')
        .findComponent(StorageTypeWarning);

      expect(storageTypeWarning.exists()).toBe(true);
    });
  });

  describe('Sorting', () => {
    it('will allow sorting for fields that have sorting enabled', () => {
      createComponent({
        props: {
          enableSortableFields: true,
        },
      });
      expect(findTable().props('fields')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ key: 'storage', sortable: true }),
          expect.objectContaining({ key: 'repository', sortable: true }),
          expect.objectContaining({ key: 'buildArtifacts', sortable: true }),
          expect.objectContaining({ key: 'lfsObjects', sortable: true }),
          expect.objectContaining({ key: 'packages', sortable: true }),
          expect.objectContaining({ key: 'wiki', sortable: true }),
          expect.objectContaining({ key: 'containerRegistry', sortable: true }),
        ]),
      );
    });

    it('will disable sorting by storage field', () => {
      createComponent();
      expect(findTable().props('fields')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ key: 'storage', sortable: false }),
          expect.objectContaining({ key: 'repository', sortable: false }),
          expect.objectContaining({ key: 'buildArtifacts', sortable: false }),
          expect.objectContaining({ key: 'lfsObjects', sortable: false }),
          expect.objectContaining({ key: 'packages', sortable: false }),
          expect.objectContaining({ key: 'wiki', sortable: false }),
          expect.objectContaining({ key: 'containerRegistry', sortable: false }),
        ]),
      );
    });
  });

  describe('Project items are rendered', () => {
    describe.each(projectList)('$name', (project) => {
      let tableText;

      beforeEach(() => {
        createComponent();
        tableText = findTable().text();
      });

      it('renders project name with namespace', () => {
        const relativeProjectPath = project.nameWithNamespace.split(' / ').slice(1).join(' / ');

        expect(tableText).toContain(relativeProjectPath);
      });

      it.each(storageTypes)('$key', ({ key }) => {
        const expectedText = numberToHumanSize(project.statistics[`${key}Size`], 1);

        expect(tableText).toContain(expectedText);
      });
    });

    it.each`
      project           | projectUrlWithUsageQuotas
      ${projectList[0]} | ${'http://localhost/frontend-fixtures/twitter/-/usage_quotas'}
      ${projectList[1]} | ${'http://localhost/frontend-fixtures/html5-boilerplate/-/usage_quotas'}
    `('renders project link as usage_quotas URL', ({ project, projectUrlWithUsageQuotas }) => {
      createComponent({ props: { projects: [project] } });

      expect(wrapper.findByTestId('project-link').attributes('href')).toBe(
        projectUrlWithUsageQuotas,
      );
    });
  });

  describe('Empty state', () => {
    it('displays empty state message', () => {
      createComponent({ props: { projects: [] } });
      expect(findTable().findAll('tr').at(1).text()).toBe('No projects to display.');
    });
  });
});
