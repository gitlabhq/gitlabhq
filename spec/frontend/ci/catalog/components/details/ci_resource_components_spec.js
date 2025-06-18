import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlEmptyState, GlIcon, GlLink, GlLoadingIcon, GlTableLite } from '@gitlab/ui';
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
      stubs: {
        HelpIcon: true,
        GlIcon: true,
        GlTableLite: true,
        GlTruncate: true,
      },
    });

    await waitForPromises();
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findInputHelpLink = () => wrapper.findComponent(GlLink);
  const findInputHelpIcon = () => wrapper.findComponent(GlIcon);
  const findCodeSnippetContainer = (i) => wrapper.findAllByTestId('copy-to-clipboard').at(i);
  const findComponents = () => wrapper.findAllByTestId('component-section');
  const findUsageCounts = () => wrapper.findAllByTestId('usage-count');

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

      describe('usage count', () => {
        it('renders the usage count for each component', () => {
          expect(findUsageCounts()).toHaveLength(components.length);
        });

        it('displays the correct usage count for each component', () => {
          components.forEach((component, index) => {
            expect(findUsageCounts().at(index).text()).toBe(
              components[index].last30DayUsageCount.toString(),
            );
          });
        });

        it('shows the correct tooltip text', () => {
          findUsageCounts().wrappers.forEach((usageCount) => {
            const tooltip = usageCount.attributes('title');
            expect(tooltip).toBe(
              'The number of projects that used the component in the last 30 days.',
            );
          });
        });
      });

      describe('inputs', () => {
        it('renders the help link', () => {
          expect(findInputHelpLink().exists()).toBe(true);
          expect(findInputHelpLink().attributes('href')).toBe(
            '/help/ci/inputs/_index.md#define-input-parameters-with-specinputs',
          );
          expect(findInputHelpLink().attributes('title')).toBe('Learn more');
        });

        it('renders the help icon', () => {
          expect(findInputHelpIcon().exists()).toBe(true);
        });

        it('renders the component parameter attributes', () => {
          expect(wrapper.findComponent(GlTableLite).exists()).toBe(true);
        });
      });
    });
  });
});
