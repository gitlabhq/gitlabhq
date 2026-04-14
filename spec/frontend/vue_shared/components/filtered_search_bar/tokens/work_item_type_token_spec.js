import { GlFilteredSearchSuggestion, GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import WorkItemTypeToken from '~/vue_shared/components/filtered_search_bar/tokens/work_item_type_token.vue';
import workItemTypesConfigurationQuery from '~/work_items/graphql/work_item_types_configuration.query.graphql';
import { mockWorkItemTypesConfigurationResponse } from 'ee_else_ce_jest/work_items/mock_data';

jest.mock('~/alert');
jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('WorkItemTypeToken', () => {
  let wrapper;

  const mockTypeToken = {
    type: 'type',
    title: 'Type',
    token: WorkItemTypeToken,
    fullPath: 'full-path',
  };

  const namespaceQueryHandler = jest.fn().mockResolvedValue(mockWorkItemTypesConfigurationResponse);

  const findBaseToken = () => wrapper.findComponent(BaseToken);
  const findSuggestions = () => wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findTokenSegments = () => wrapper.findAllComponents(GlFilteredSearchTokenSegment);

  function createComponent({
    props = {},
    stubs = {},
    listeners = {},
    queryHandler = namespaceQueryHandler,
  } = {}) {
    wrapper = mount(WorkItemTypeToken, {
      apolloProvider: createMockApollo([[workItemTypesConfigurationQuery, queryHandler]]),
      propsData: {
        active: false,
        config: mockTypeToken,
        value: { data: '' },
        ...props,
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
        suggestionsListClass: () => 'custom-class',
        termsAsTokens: () => false,
      },
      stubs: {
        Portal: true,
        BaseToken,
        GlFilteredSearchSuggestionList: {
          template: '<div></div>',
          methods: {
            getValue: () => '=',
          },
        },
        ...stubs,
      },
      listeners,
    });
  }

  describe('template', () => {
    it.each`
      data       | expectedText
      ${'ISSUE'} | ${'Issue'}
      ${'TASK'}  | ${'Task'}
    `('when "$value" is selected, shows "$expectedText"', async ({ data, expectedText }) => {
      createComponent({ props: { value: { data } } });
      await waitForPromises();

      const tokenSegments = findTokenSegments();
      expect(tokenSegments).toHaveLength(3); // Type, =, "Issue"
      expect(tokenSegments.at(2).text()).toBe(expectedText);
    });

    it('renders isFilterableListView suggestions by default', async () => {
      createComponent({
        props: { active: true },
        stubs: { GlFilteredSearchSuggestionList: false },
      });
      await waitForPromises();

      expect(findSuggestions().length).toBeGreaterThan(0);
      expect(findBaseToken().props('suggestions')).toMatchObject([
        { name: 'Issue' },
        { name: 'Task' },
      ]);
    });

    it('renders isFilterableBoardView suggestions when isFilterableBoardView config is passed', async () => {
      createComponent({
        props: { active: true, config: { ...mockTypeToken, isFilterableBoardView: true } },
        stubs: { GlFilteredSearchSuggestionList: false },
      });
      await waitForPromises();

      expect(findSuggestions().length).toBeGreaterThan(0);
      expect(findBaseToken().props('suggestions')).toMatchObject([{ name: 'Issue' }]);
    });

    it('emits input event when token value changes', () => {
      const mockInput = jest.fn();
      createComponent({ listeners: { input: mockInput } });

      findBaseToken().vm.$emit('input', [{ data: 'ISSUE', operator: '=' }]);

      expect(mockInput).toHaveBeenLastCalledWith([{ data: 'ISSUE', operator: '=' }]);
    });
  });

  describe('with multi-select support', () => {
    it('passes array data to BaseToken for "is one of" operator', () => {
      createComponent({
        props: {
          config: { ...mockTypeToken, multiSelect: true },
          value: { data: ['ISSUE', 'TASK'], operator: '||' },
        },
      });

      expect(findBaseToken().props('value')).toEqual({
        data: ['ISSUE', 'TASK'],
        operator: '||',
      });
    });

    it('passes array data to BaseToken for "is not one of" operator', () => {
      createComponent({
        props: {
          config: { ...mockTypeToken, multiSelect: true },
          value: { data: ['ISSUE', 'TASK'], operator: '!=' },
        },
      });

      expect(findBaseToken().props('value')).toEqual({
        data: ['ISSUE', 'TASK'],
        operator: '!=',
      });
    });
  });

  describe('workItemTypesConfigurationQuery', () => {
    it('is called on mount', () => {
      createComponent();

      expect(namespaceQueryHandler).toHaveBeenLastCalledWith({ fullPath: 'full-path' });
    });

    it('renders an error when an error occurs', async () => {
      createComponent({ queryHandler: jest.fn().mockRejectedValue(new Error('aaah')) });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong when fetching work item types. Please try again',
      });
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('aaah'));
    });
  });
});
