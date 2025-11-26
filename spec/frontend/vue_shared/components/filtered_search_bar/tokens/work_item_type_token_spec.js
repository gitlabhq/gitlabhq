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
  { icon: 'work-item-issue', title: 'Issue', value: 'issue' },
  { icon: 'work-item-incident', title: 'Incident', value: 'incident' },
  { icon: 'work-item-task', title: 'Task', value: 'task' },
];

const mockTypeToken = {
  type: 'type',
  title: 'Type',
  icon: 'work-item-issue',
  token: WorkItemTypeToken,
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
      hasEpicsFeature: false,
      hasOkrsFeature: false,
      hasQualityManagementFeature: false,
      isGroupIssuesList: false,
      isProject: false,
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
        value: { data: 'issue' },
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
      value         | expectedText
      ${'issue'}    | ${'Issue'}
      ${'incident'} | ${'Incident'}
      ${'task'}     | ${'Task'}
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

      findBaseToken().vm.$emit('input', [{ data: 'issue', operator: '=' }]);

      expect(mockInput).toHaveBeenLastCalledWith([{ data: 'issue', operator: '=' }]);
    });

    describe('with multi-select support', () => {
      it('passes array data to BaseToken for "is one of" operator', () => {
        wrapper = createComponent({
          config: {
            ...mockTypeToken,
            multiSelect: true,
          },
          value: { data: ['issue', 'incident'], operator: '||' },
        });

        expect(findBaseToken().props('value')).toEqual({
          data: ['issue', 'incident'],
          operator: '||',
        });
      });

      it('passes array data to BaseToken for "is not one of" operator', () => {
        wrapper = createComponent({
          config: {
            ...mockTypeToken,
            multiSelect: true,
          },
          value: { data: ['issue', 'task'], operator: '!=' },
        });

        expect(findBaseToken().props('value')).toEqual({
          data: ['issue', 'task'],
          operator: '!=',
        });
      });
    });
  });
});
