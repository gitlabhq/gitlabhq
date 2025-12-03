import { GlFilteredSearchSuggestion, GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import WorkItemTypeToken from '~/vue_shared/components/filtered_search_bar/tokens/work_item_type_token.vue';

const defaultStubs = {
  Portal: true,
  BaseToken,
  GlFilteredSearchSuggestionList: {
    template: '<div></div>',
    methods: {
      getValue: () => '=',
    },
  },
};

const mockWorkItemTypes = [
  { title: 'Issue', value: 'ISSUE' },
  { title: 'Incident', value: 'INCIDENT' },
  { title: 'Task', value: 'TASK' },
  { title: 'Key result', value: 'KEY_RESULT' },
];

const mockTypeToken = {
  type: 'type',
  title: 'Type',
  token: WorkItemTypeToken,
  initialWorkItemTypes: mockWorkItemTypes,
};

function createComponent(options = {}) {
  const {
    config = mockTypeToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
    listeners = {},
  } = options;
  return mount(WorkItemTypeToken, {
    propsData: {
      config,
      value,
      active,
      cursorPosition: 'start',
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      suggestionsListClass: () => 'custom-class',
      termsAsTokens: () => false,
    },
    stubs,
    listeners,
  });
}

describe('WorkItemTypeToken', () => {
  let wrapper;

  const findBaseToken = () => wrapper.findComponent(BaseToken);
  const findSuggestions = () => wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findTokenSegments = () => wrapper.findAllComponents(GlFilteredSearchTokenSegment);

  describe('template', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        value: { data: 'ISSUE' },
      });

      await nextTick();
    });

    it('renders base-token component', () => {
      const baseTokenEl = findBaseToken();

      expect(baseTokenEl.exists()).toBe(true);
    });

    it('renders token item when single value is selected', () => {
      const tokenSegments = findTokenSegments();

      expect(tokenSegments).toHaveLength(3); // Type, =, "Issue"
      expect(tokenSegments.at(2).text()).toBe('Issue');
    });

    it.each`
      value           | expectedText
      ${'ISSUE'}      | ${'Issue'}
      ${'INCIDENT'}   | ${'Incident'}
      ${'TASK'}       | ${'Task'}
      ${'KEY_RESULT'} | ${'Key result'}
    `('when "$value" is selected, shows "$expectedText"', async ({ value, expectedText }) => {
      wrapper = createComponent({
        value: { data: value, operator: '=' },
      });

      await nextTick();

      const tokenSegments = findTokenSegments();
      expect(tokenSegments.at(2).text()).toBe(expectedText);
    });

    it('passes correct suggestions to BaseToken', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockTypeToken },
        stubs: { Portal: true },
      });

      await nextTick();

      expect(findBaseToken().props('suggestions')).toEqual(mockWorkItemTypes);
    });

    it('renders all available suggestions when active', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockTypeToken },
        stubs: { Portal: true },
      });

      await nextTick();

      const suggestions = findSuggestions();

      expect(suggestions.length).toBeGreaterThan(0);
      expect(findBaseToken().props('suggestions')).toEqual(mockWorkItemTypes);
    });

    it('emits input event when token value changes', () => {
      const mockInput = jest.fn();
      wrapper = createComponent({
        listeners: {
          input: mockInput,
        },
      });

      findBaseToken().vm.$emit('input', [{ data: 'ISSUE', operator: '=' }]);

      expect(mockInput).toHaveBeenLastCalledWith([{ data: 'ISSUE', operator: '=' }]);
    });

    describe('with multi-select support', () => {
      it('passes array data to BaseToken for "is one of" operator', () => {
        wrapper = createComponent({
          config: {
            ...mockTypeToken,
            multiSelect: true,
          },
          value: { data: ['ISSUE', 'INCIDENT'], operator: '||' },
        });

        expect(findBaseToken().props('value')).toEqual({
          data: ['ISSUE', 'INCIDENT'],
          operator: '||',
        });
      });

      it('passes array data to BaseToken for "is not one of" operator', () => {
        wrapper = createComponent({
          config: {
            ...mockTypeToken,
            multiSelect: true,
          },
          value: { data: ['ISSUE', 'TASK'], operator: '!=' },
        });

        expect(findBaseToken().props('value')).toEqual({
          data: ['ISSUE', 'TASK'],
          operator: '!=',
        });
      });
    });

    describe('with fetchWorkItemTypes', () => {
      it('fetches work item types when fetch-suggestions is triggered', async () => {
        const mockFetch = jest.fn().mockResolvedValue({
          data: {
            workspace: {
              workItemTypes: {
                nodes: [{ name: 'Epic' }, { name: 'Key result' }],
              },
            },
          },
        });

        wrapper = createComponent({
          config: {
            ...mockTypeToken,
            initialWorkItemTypes: [],
            fetchWorkItemTypes: mockFetch,
          },
        });

        findBaseToken().trigger('fetch-suggestions');

        await nextTick();

        expect(mockFetch).toHaveBeenCalled();
      });

      it('transforms fetched work item types correctly', async () => {
        const mockFetch = jest.fn().mockResolvedValue({
          data: {
            workspace: {
              workItemTypes: {
                nodes: [{ name: 'Epic' }, { name: 'Key result' }, { name: 'Requirements' }],
              },
            },
          },
        });

        wrapper = createComponent({
          config: {
            ...mockTypeToken,
            initialWorkItemTypes: [],
            fetchWorkItemTypes: mockFetch,
          },
        });

        findBaseToken().trigger('fetch-suggestions');

        await nextTick();

        await mockFetch.mock.results[0].value;

        await nextTick();

        const baseToken = findBaseToken();
        expect(baseToken.props('suggestions')).toEqual([
          { value: 'EPIC', title: 'Epic' },
          { value: 'KEY_RESULT', title: 'Key result' },
          { value: 'REQUIREMENTS', title: 'Requirements' },
        ]);
      });
    });
  });
});
