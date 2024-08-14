import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlEmptyState, GlIcon, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CiResourceComponents from '~/ci/catalog/components/details/ci_resource_components.vue';
import getCiCatalogcomponentComponents from '~/ci/catalog/graphql/queries/get_ci_catalog_resource_components.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { mockComponents, mockComponentsEmpty } from '../../mock';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('CiResourceComponents', () => {
  let wrapper;
  let mockComponentsResponse;

  const components = mockComponents.data.ciCatalogResource.versions.nodes[0].components.nodes;

  const resourcePath = 'twitter/project-1';

  const defaultProps = { resourcePath };

  const createComponent = async () => {
    const handlers = [[getCiCatalogcomponentComponents, mockComponentsResponse]];
    const mockApollo = createMockApollo(handlers);

    wrapper = mountExtended(CiResourceComponents, {
      propsData: {
        ...defaultProps,
      },
      apolloProvider: mockApollo,
    });

    await waitForPromises();
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findInputHelpLink = () => wrapper.findComponent(GlLink);
  const findInputHelpIcon = () => wrapper.findComponent(GlIcon);
  const findCodeSnippetContainer = (i) => wrapper.findAllByTestId('copy-to-clipboard').at(i);
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
    describe('and there is no metadata', () => {
      beforeEach(async () => {
        mockComponentsResponse.mockResolvedValue(mockComponentsEmpty);
        await createComponent();
      });

      it('renders the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findEmptyState().props().title).toBe('Component details not available');
      });

      it('does not render components', () => {
        expect(findComponents()).toHaveLength(0);
      });
    });

    describe('and there is metadata', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('does not render the empty state', () => {
        expect(findEmptyState().exists()).toBe(false);
      });

      it('renders every component', () => {
        expect(findComponents()).toHaveLength(components.length);
      });

      it('renders the component name', () => {
        components.forEach((component) => {
          expect(wrapper.text()).toContain(component.name);
        });
      });

      it('renders the component code snippet', () => {
        components.forEach((component, i) => {
          const codeSnippetContainer = findCodeSnippetContainer(i);
          const expectedCodeSnippet = `include:
  - component: ${component.includePath}`;

          expect(codeSnippetContainer.exists()).toBe(true);
          expect(codeSnippetContainer.text()).toContain(expectedCodeSnippet);
        });
      });

      describe('inputs', () => {
        it('renders the help link', () => {
          expect(findInputHelpLink().exists()).toBe(true);
          expect(findInputHelpLink().attributes('href')).toBe(
            '/help/ci/yaml/inputs#define-input-parameters-with-specinputs',
          );
          expect(findInputHelpLink().attributes('title')).toBe('Learn more');
        });

        it('renders the help icon', () => {
          expect(findInputHelpIcon().exists()).toBe(true);
          expect(findInputHelpIcon().props('name')).toBe('question-o');
        });

        it('renders the component parameter attributes', () => {
          const [firstComponent] = components;

          firstComponent.inputs.forEach((input) => {
            expect(findComponents().at(0).text()).toContain(input.name);
            expect(findComponents().at(0).text()).toContain(input.default);
            expect(findComponents().at(0).text()).toContain(input.description);
            expect(findComponents().at(0).text()).toContain('true');
            expect(findComponents().at(0).text()).toContain(input.type.toLowerCase());
          });
        });
      });
    });
  });
});
