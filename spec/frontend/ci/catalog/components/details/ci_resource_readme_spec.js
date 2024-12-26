import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourceReadme from '~/ci/catalog/components/details/ci_resource_readme.vue';
import getCiCatalogResourceReadme from '~/ci/catalog/graphql/queries/get_ci_catalog_resource_readme.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/alert');
jest.mock('~/behaviors/markdown/render_gfm');

Vue.use(VueApollo);

const versionedReadmeHtml = '<h1>This is version one readme</h1>';
const resourceId = 'gid://gitlab/Ci::Catalog::Resource/1';

describe('CiResourceReadme', () => {
  let wrapper;
  let mockReadmeResponse;

  const readmeMockData = {
    data: {
      ciCatalogResource: {
        id: resourceId,
        webPath: 'twitter/project-1',
        versions: {
          nodes: [
            {
              id: 'gid://gitlab/Ci::Catalog::Resources::Version/1',
              name: '1.0.1',
              readmeHtml: versionedReadmeHtml,
            },
          ],
        },
      },
    },
  };

  const defaultProps = {
    resourcePath: readmeMockData.data.ciCatalogResource.webPath,
    version: readmeMockData.data.ciCatalogResource.versions.nodes[0].name,
  };

  const createComponent = ({ props = {}, data = {} } = {}) => {
    const handlers = [[getCiCatalogResourceReadme, mockReadmeResponse]];

    wrapper = shallowMountExtended(CiResourceReadme, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      data() {
        return {
          ...data,
        };
      },
      apolloProvider: createMockApollo(handlers),
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(() => {
    mockReadmeResponse = jest.fn();
  });

  describe('when loading', () => {
    beforeEach(() => {
      mockReadmeResponse.mockResolvedValue(readmeMockData);
      createComponent();
    });

    it('renders only a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(wrapper.html()).not.toContain(versionedReadmeHtml);
    });
  });

  describe('when mounted', () => {
    beforeEach(async () => {
      mockReadmeResponse.mockResolvedValue(readmeMockData);

      createComponent();
      await waitForPromises();
    });

    it('renders a versioned readme', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(wrapper.html()).toContain(versionedReadmeHtml);
    });

    it('calls `renderGFM` to ensure that all gitlab-flavoured markdown is rendered on the README', async () => {
      await nextTick();

      expect(renderGFM).toHaveBeenCalledWith(
        expect.objectContaining({
          innerHTML: expect.stringContaining(versionedReadmeHtml),
        }),
      );
    });

    it('does not render an error', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('when there is an error loading the readme', () => {
    beforeEach(async () => {
      mockReadmeResponse.mockRejectedValue({ errors: [] });

      createComponent();
      await waitForPromises();
    });

    it('calls the createAlert function to show an error', () => {
      expect(createAlert).toHaveBeenCalled();
      expect(createAlert).toHaveBeenCalledWith({
        message: "There was a problem loading this project's readme content.",
      });
    });
  });
});
