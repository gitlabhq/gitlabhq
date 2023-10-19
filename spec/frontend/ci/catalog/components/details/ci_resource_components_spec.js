import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { resolvers } from '~/ci/catalog/graphql/settings';
import CiResourceComponents from '~/ci/catalog/components/details/ci_resource_components.vue';
import getCiCatalogcomponentComponents from '~/ci/catalog/graphql/queries/get_ci_catalog_resource_components.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { mockComponents } from '../../mock';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('CiResourceComponents', () => {
  let wrapper;
  let mockComponentsResponse;

  const components = mockComponents.data.ciCatalogResource.components.nodes;

  const resourceId = 'gid://gitlab/Ci::Catalog::Resource/1';

  const defaultProps = { resourceId };

  const createComponent = async () => {
    const handlers = [[getCiCatalogcomponentComponents, mockComponentsResponse]];
    const mockApollo = createMockApollo(handlers, resolvers);

    wrapper = mountExtended(CiResourceComponents, {
      propsData: {
        ...defaultProps,
      },
      apolloProvider: mockApollo,
    });

    await waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findComponents = () => wrapper.findAllByTestId('component-section');

  beforeEach(() => {
    mockComponentsResponse = jest.fn();
    mockComponentsResponse.mockResolvedValue(mockComponents);
  });

  describe('when queries are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('render a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render components', () => {
      expect(findComponents()).toHaveLength(0);
    });

    it('does not throw an error', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('when components query throws an error', () => {
    beforeEach(async () => {
      mockComponentsResponse.mockRejectedValue();
      await createComponent();
    });

    it('calls createAlert with the correct message', () => {
      expect(createAlert).toHaveBeenCalled();
      expect(createAlert).toHaveBeenCalledWith({
        message: "There was an error fetching this resource's components",
      });
    });

    it('does not render the loading state', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when queries have loaded', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders every component', () => {
      expect(findComponents()).toHaveLength(components.length);
    });

    it('renders the component name, description and snippet', () => {
      components.forEach((component) => {
        expect(wrapper.text()).toContain(component.name);
        expect(wrapper.text()).toContain(component.description);
        expect(wrapper.text()).toContain(component.path);
      });
    });

    describe('inputs', () => {
      it('renders the component parameter attributes', () => {
        const [firstComponent] = components;

        firstComponent.inputs.nodes.forEach((input) => {
          expect(findComponents().at(0).text()).toContain(input.name);
          expect(findComponents().at(0).text()).toContain(input.defaultValue);
          expect(findComponents().at(0).text()).toContain('Yes');
        });
      });
    });
  });
});
