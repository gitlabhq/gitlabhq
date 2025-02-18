import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ModelSelectionDropdown from '~/ml/experiment_tracking/routes/candidates/promote/model_selection_dropdown.vue';
import searchModelsQuery from '~/ml/experiment_tracking/graphql/queries/search_models.query.graphql';
import { mockModelItems, mockModelNodes, mockModelNames, mockModelsQueryResult } from './mock_data';

Vue.use(VueApollo);

describe('ml/experiment_tracking/components/model_selection_dropdown', () => {
  let wrapper;
  let apolloProvider;
  const searchModelsQueryResolver = jest.fn().mockResolvedValue(mockModelsQueryResult);

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const buildWrapper = ({
    mountFn = shallowMountExtended,
    searchModelsQueryHandler = searchModelsQueryResolver,
    value = null,
  } = {}) => {
    const requestHandlers = [[searchModelsQuery, searchModelsQueryHandler]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountFn(ModelSelectionDropdown, {
      propsData: {
        value,
        projectPath: 'group/project',
      },
      apolloProvider,
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  describe('default state', () => {
    beforeEach(async () => {
      buildWrapper();
      await waitForPromises();
    });

    it('initializes collapsible list box', () => {
      expect(findCollapsibleListbox().props()).toMatchObject({
        block: true,
        searchable: true,
        items: mockModelItems,
        noResultsText: 'No results',
        toggleText: 'Select a model',
      });
    });

    it('fetches model list', () => {
      expect(searchModelsQueryResolver).toHaveBeenCalledWith({
        name: '',
        fullPath: 'group/project',
      });
    });

    it('displays model list', () => {
      mockModelNames.forEach((name) => {
        expect(findCollapsibleListbox().text()).toContain(name);
      });
    });
  });

  describe('when there is a selected model', () => {
    const selectedModel = mockModelNodes[0];

    beforeEach(async () => {
      buildWrapper({ value: selectedModel });
      await waitForPromises();
    });

    it('displays the model name as the toggle button text', () => {
      expect(findCollapsibleListbox().props().toggleText).toBe(selectedModel.name);
    });
  });

  describe('when selecting a model', () => {
    it('emits input event with the selected model', async () => {
      const itemIndex = 0;
      const selectedModel = mockModelNodes[itemIndex];

      buildWrapper({ mountFn: mountExtended });
      await waitForPromises();

      await findCollapsibleListbox()
        .findAllComponents(GlListboxItem)
        .at(itemIndex)
        .trigger('click');

      expect(wrapper.emitted('input')).toEqual([[selectedModel]]);
    });
  });

  describe('when searching for a model', () => {
    it('retriggers GraphQL query with the search term entered', async () => {
      buildWrapper({ mountFn: mountExtended });
      await waitForPromises();

      await findCollapsibleListbox().vm.$emit('search', 'foo');

      expect(searchModelsQueryResolver).toHaveBeenCalledWith({
        name: 'foo',
        fullPath: 'group/project',
      });
    });
  });

  describe('when the search models graphql query fails', () => {
    beforeEach(async () => {
      const handler = jest.fn().mockRejectedValueOnce(new Error('Failed to search models'));

      buildWrapper({ mountFn: mountExtended, searchModelsQueryHandler: handler });
      await waitForPromises();
    });

    it('displays empty results', () => {
      expect(findCollapsibleListbox().props().items).toEqual([]);
    });

    it('logs a Sentry error', () => {
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });
});
