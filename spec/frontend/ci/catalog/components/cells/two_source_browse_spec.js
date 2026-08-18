import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlEmptyState, GlTabs, GlSearchBoxByType, GlSorting } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TwoSourceBrowse from '~/ci/catalog/components/cells/two_source_browse.vue';
import CiResourcesListItem from '~/ci/catalog/components/list/ci_resources_list_item.vue';
import getCatalogResources from '~/ci/catalog/graphql/queries/get_ci_catalog_resources.query.graphql';
import getCiCatalogBundledResources from '~/ci/catalog/graphql/queries/get_ci_catalog_bundled_resources.query.graphql';
import { VERIFICATION_LEVEL_UNVERIFIED } from '~/ci/catalog/constants';
import { catalogResponseBody, emptyCatalogResponseBody } from '../../mock';

Vue.use(VueApollo);

const orgNodes = catalogResponseBody.data.ciCatalogResources.nodes;
const firstOrgName = orgNodes[0].name;

const bundledNode = (id, name, latestReleasedAt = '2026-02-01T00:00:00Z') => ({
  __typename: 'CiCatalogBundledResource',
  id: `gid://gitlab/Ci::Catalog::BundledResource/${id}`,
  name,
  description: `${name} description`,
  fullPath: `gitlab.com/components/${name}`,
  serverFqdn: 'gitlab.com',
  latestReleasedAt,
  latestVersionName: 'v5.2.0',
});

const bundledResponse = (nodes) => ({
  data: {
    ciCatalogBundledResources: {
      __typename: 'CiCatalogBundledResourceConnection',
      pageInfo: {
        __typename: 'PageInfo',
        startCursor: null,
        endCursor: null,
        hasNextPage: false,
        hasPreviousPage: false,
      },
      nodes,
    },
  },
});

describe('TwoSourceBrowse', () => {
  let wrapper;

  const createComponent = ({
    orgResponse = catalogResponseBody,
    bundledNodes = [bundledNode(1, 'sast')],
  } = {}) => {
    const handlers = [
      [getCatalogResources, jest.fn().mockResolvedValue(orgResponse)],
      [getCiCatalogBundledResources, jest.fn().mockResolvedValue(bundledResponse(bundledNodes))],
    ];

    wrapper = mountExtended(TwoSourceBrowse, {
      apolloProvider: createMockApollo(handlers),
      stubs: { CiResourcesListItem: true },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findItems = () => wrapper.findAllComponents(CiResourcesListItem);
  const selectBundledTab = async () => {
    findTabs().vm.$emit('input', 1);
    await waitForPromises();
  };

  it('shows a loading icon while the queries are in flight', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('once loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the organization resources on the default tab with stats + author enabled', () => {
      expect(findItems()).toHaveLength(orgNodes.length);
      expect(findItems().at(0).props('showStats')).toBe(true);
      expect(findItems().at(0).props('showAuthor')).toBe(true);
    });

    describe('bundled tab', () => {
      beforeEach(selectBundledTab);

      it('renders the bundled resources with stats + author hidden', () => {
        expect(findItems()).toHaveLength(1);
        expect(findItems().at(0).props('showStats')).toBe(false);
        expect(findItems().at(0).props('showAuthor')).toBe(false);
      });

      it('adapts the bundled resource into the card shape', () => {
        const resource = findItems().at(0).props('resource');

        expect(resource.name).toBe('sast');
        expect(resource.webPath).toBe('gitlab.com/components/sast');
        expect(resource.verificationLevel).toBe(VERIFICATION_LEVEL_UNVERIFIED);
        expect(resource.versions.nodes[0]).toMatchObject({
          name: 'v5.2.0',
          releasedAt: '2026-02-01T00:00:00Z',
        });
      });
    });
  });

  describe('empty states', () => {
    it('shows the empty state when a source has no resources', async () => {
      createComponent({ orgResponse: emptyCatalogResponseBody });
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findItems()).toHaveLength(0);
    });
  });

  describe('sorting', () => {
    const findSorting = () => wrapper.findComponent(GlSorting);
    const renderedNames = () => findItems().wrappers.map((item) => item.props('resource').name);

    beforeEach(async () => {
      createComponent({
        bundledNodes: [
          bundledNode(1, 'older', '2026-01-01T00:00:00Z'),
          bundledNode(2, 'newer', '2026-03-01T00:00:00Z'),
        ],
      });
      await waitForPromises();
      await selectBundledTab();
    });

    it('sorts by last released with the newest first', () => {
      expect(renderedNames()).toEqual(['newer', 'older']);
    });

    it('reverses the order when the sort direction is toggled', async () => {
      findSorting().vm.$emit('sortDirectionChange', true);
      await waitForPromises();

      expect(renderedNames()).toEqual(['older', 'newer']);
    });
  });

  describe('search', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('filters the list by name', async () => {
      findSearch().vm.$emit('input', firstOrgName);
      await waitForPromises();

      expect(findItems()).toHaveLength(1);
      expect(findItems().at(0).props('resource').name).toBe(firstOrgName);
    });
  });
});
