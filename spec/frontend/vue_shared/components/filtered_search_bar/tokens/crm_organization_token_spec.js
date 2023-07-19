import {
  GlFilteredSearchSuggestion,
  GlFilteredSearchTokenSegment,
  GlDropdownDivider,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { OPTIONS_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import CrmOrganizationToken from '~/vue_shared/components/filtered_search_bar/tokens/crm_organization_token.vue';
import searchCrmOrganizationsQuery from '~/vue_shared/components/filtered_search_bar/queries/search_crm_organizations.query.graphql';

import {
  mockCrmOrganizations,
  mockCrmOrganizationToken,
  mockGroupCrmOrganizationsQueryResponse,
  mockProjectCrmOrganizationsQueryResponse,
} from '../mock_data';

jest.mock('~/alert');

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

describe('CrmOrganizationToken', () => {
  Vue.use(VueApollo);

  let wrapper;

  const getBaseToken = () => wrapper.findComponent(BaseToken);

  const searchGroupCrmOrganizationsQueryHandler = jest
    .fn()
    .mockResolvedValue(mockGroupCrmOrganizationsQueryResponse);
  const searchProjectCrmOrganizationsQueryHandler = jest
    .fn()
    .mockResolvedValue(mockProjectCrmOrganizationsQueryResponse);

  const mountComponent = ({
    config = mockCrmOrganizationToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
    listeners = {},
    queryHandler = searchGroupCrmOrganizationsQueryHandler,
  } = {}) => {
    wrapper = mount(CrmOrganizationToken, {
      apolloProvider: createMockApollo([[searchCrmOrganizationsQuery, queryHandler]]),
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
  };

  describe('methods', () => {
    describe('fetchOrganizations', () => {
      describe('for groups', () => {
        beforeEach(() => {
          mountComponent();
        });

        it('calls the apollo query providing the searchString when search term is a string', async () => {
          getBaseToken().vm.$emit('fetch-suggestions', 'foo');
          await waitForPromises();

          expect(createAlert).not.toHaveBeenCalled();
          expect(searchGroupCrmOrganizationsQueryHandler).toHaveBeenCalledWith({
            fullPath: 'group',
            isProject: false,
            searchString: 'foo',
            searchIds: null,
          });
          expect(getBaseToken().props('suggestions')).toEqual(mockCrmOrganizations);
        });

        it('calls the apollo query providing the searchId when search term is a number', async () => {
          getBaseToken().vm.$emit('fetch-suggestions', '5');
          await waitForPromises();

          expect(createAlert).not.toHaveBeenCalled();
          expect(searchGroupCrmOrganizationsQueryHandler).toHaveBeenCalledWith({
            fullPath: 'group',
            isProject: false,
            searchString: null,
            searchIds: ['gid://gitlab/CustomerRelations::Organization/5'],
          });
          expect(getBaseToken().props('suggestions')).toEqual(mockCrmOrganizations);
        });
      });

      describe('for projects', () => {
        beforeEach(() => {
          mountComponent({
            config: {
              fullPath: 'project',
              isProject: true,
            },
            queryHandler: searchProjectCrmOrganizationsQueryHandler,
          });
        });

        it('calls the apollo query providing the searchString when search term is a string', async () => {
          getBaseToken().vm.$emit('fetch-suggestions', 'foo');
          await waitForPromises();

          expect(createAlert).not.toHaveBeenCalled();
          expect(searchProjectCrmOrganizationsQueryHandler).toHaveBeenCalledWith({
            fullPath: 'project',
            isProject: true,
            searchString: 'foo',
            searchIds: null,
          });
          expect(getBaseToken().props('suggestions')).toEqual(mockCrmOrganizations);
        });

        it('calls the apollo query providing the searchId when search term is a number', async () => {
          getBaseToken().vm.$emit('fetch-suggestions', '5');
          await waitForPromises();

          expect(createAlert).not.toHaveBeenCalled();
          expect(searchProjectCrmOrganizationsQueryHandler).toHaveBeenCalledWith({
            fullPath: 'project',
            isProject: true,
            searchString: null,
            searchIds: ['gid://gitlab/CustomerRelations::Organization/5'],
          });
          expect(getBaseToken().props('suggestions')).toEqual(mockCrmOrganizations);
        });
      });

      it('calls `createAlert` when request fails', async () => {
        mountComponent({ queryHandler: jest.fn().mockRejectedValue({}) });

        getBaseToken().vm.$emit('fetch-suggestions');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem fetching CRM organizations.',
        });
      });

      it('sets `loading` to false when request completes', async () => {
        mountComponent({ queryHandler: jest.fn().mockRejectedValue({}) });

        getBaseToken().vm.$emit('fetch-suggestions');

        await waitForPromises();

        expect(getBaseToken().props('suggestionsLoading')).toBe(false);
      });
    });
  });

  describe('template', () => {
    const defaultOrganizations = OPTIONS_NONE_ANY;

    it('renders base-token component', () => {
      mountComponent({
        config: { ...mockCrmOrganizationToken, initialOrganizations: mockCrmOrganizations },
        value: { data: '1' },
      });

      expect(getBaseToken().props('suggestions')).toEqual(mockCrmOrganizations);
    });

    it.each(mockCrmOrganizations)('renders token item when value is selected', (organization) => {
      mountComponent({
        config: { ...mockCrmOrganizationToken, initialOrganizations: mockCrmOrganizations },
        value: { data: `${getIdFromGraphQLId(organization.id)}` },
      });

      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // Organization, =, Organization name
      expect(tokenSegments.at(2).text()).toBe(organization.name); // Organization name
    });

    it('renders provided defaultOrganizations as suggestions', async () => {
      mountComponent({
        active: true,
        config: { ...mockCrmOrganizationToken, defaultOrganizations },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(defaultOrganizations.length);
      defaultOrganizations.forEach((organization, index) => {
        expect(suggestions.at(index).text()).toBe(organization.text);
      });
    });

    it('does not render divider when no defaultOrganizations', async () => {
      mountComponent({
        active: true,
        config: { ...mockCrmOrganizationToken, defaultOrganizations: [] },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      expect(wrapper.findComponent(GlFilteredSearchSuggestion).exists()).toBe(false);
      expect(wrapper.findComponent(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders `OPTIONS_NONE_ANY` as default suggestions', () => {
      mountComponent({
        active: true,
        config: { ...mockCrmOrganizationToken },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(OPTIONS_NONE_ANY.length);
      OPTIONS_NONE_ANY.forEach((organization, index) => {
        expect(suggestions.at(index).text()).toBe(organization.text);
      });
    });

    it('emits listeners in the base-token', () => {
      const mockInput = jest.fn();
      mountComponent({ listeners: { input: mockInput } });

      getBaseToken().vm.$emit('input', [{ data: 'mockData', operator: '=' }]);

      expect(mockInput).toHaveBeenLastCalledWith([{ data: 'mockData', operator: '=' }]);
    });
  });
});
