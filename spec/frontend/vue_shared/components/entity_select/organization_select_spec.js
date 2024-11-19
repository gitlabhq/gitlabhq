import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlCollapsibleListbox, GlAlert } from '@gitlab/ui';
import { chunk } from 'lodash';
import currentUserOrganizationsGraphQlResponse from 'test_fixtures/graphql/organizations/current_user_organizations.query.graphql.json';
import organizationsGraphQlResponse from 'test_fixtures/graphql/organizations/organizations.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationSelect from '~/vue_shared/components/entity_select/organization_select.vue';
import EntitySelect from '~/vue_shared/components/entity_select/entity_select.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import {
  ORGANIZATION_TOGGLE_TEXT,
  ORGANIZATION_HEADER_TEXT,
  FETCH_ORGANIZATIONS_ERROR,
  FETCH_ORGANIZATION_ERROR,
} from '~/vue_shared/components/entity_select/constants';
import getCurrentUserOrganizationsQuery from '~/organizations/shared/graphql/queries/current_user_organizations.query.graphql';
import getOrganizationQuery from '~/organizations/shared/graphql/queries/organization.query.graphql';
import getOrganizationsQuery from '~/organizations/shared/graphql/queries/organizations.query.graphql';
import { pageInfoMultiplePages, pageInfoEmpty } from 'jest/organizations/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

Vue.use(VueApollo);

describe('OrganizationSelect', () => {
  let wrapper;
  let mockApollo;

  // Mocks
  const {
    data: {
      currentUser: {
        organizations: { nodes },
      },
    },
  } = currentUserOrganizationsGraphQlResponse;
  const [organization] = nodes;

  // Props
  const label = 'label';
  const description = 'description';
  const inputName = 'inputName';
  const inputId = 'inputId';
  const toggleClass = 'foo-bar';

  // Finders
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findEntitySelect = () => wrapper.findComponent(EntitySelect);
  const findAlert = () => wrapper.findComponent(GlAlert);

  // Mock handlers
  const handleInput = jest.fn();
  const getCurrentUserOrganizationsQueryHandler = jest
    .fn()
    .mockResolvedValue(currentUserOrganizationsGraphQlResponse);
  const getOrganizationQueryHandler = jest.fn().mockResolvedValue({
    data: { organization },
  });

  // Helpers
  const createComponent = ({
    props = {},
    handlers = [
      [getCurrentUserOrganizationsQuery, getCurrentUserOrganizationsQueryHandler],
      [getOrganizationQuery, getOrganizationQueryHandler],
    ],
  } = {}) => {
    mockApollo = createMockApollo(handlers);

    wrapper = mountExtended(OrganizationSelect, {
      apolloProvider: mockApollo,
      propsData: {
        label,
        description,
        inputName,
        inputId,
        toggleClass,
        ...props,
      },
      listeners: {
        input: handleInput,
      },
    });
  };
  const openListbox = () => findListbox().vm.$emit('shown');

  describe('entity_select props', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      prop                   | expectedValue
      ${'label'}             | ${label}
      ${'description'}       | ${description}
      ${'inputName'}         | ${inputName}
      ${'inputId'}           | ${inputId}
      ${'defaultToggleText'} | ${ORGANIZATION_TOGGLE_TEXT}
      ${'headerText'}        | ${ORGANIZATION_HEADER_TEXT}
      ${'toggleClass'}       | ${toggleClass}
      ${'searchable'}        | ${true}
    `('passes the $prop prop to entity-select', ({ prop, expectedValue }) => {
      expect(findEntitySelect().props(prop)).toBe(expectedValue);
    });
  });

  describe('on mount', () => {
    it('fetches organizations when the listbox is opened', async () => {
      createComponent();
      openListbox();
      await waitForPromises();

      const expectedItems = nodes.map((node) => ({
        ...node,
        text: node.name,
        value: getIdFromGraphQLId(node.id),
      }));

      expect(findListbox().props('items')).toEqual(expectedItems);
    });

    describe('with an initial selection', () => {
      it("fetches the initially selected value's name", async () => {
        createComponent({ props: { initialSelection: organization.id } });
        await waitForPromises();

        expect(findListbox().props('toggleText')).toBe(organization.name);
      });

      it('show an error if fetching initially selected fails', async () => {
        createComponent({
          props: { initialSelection: organization.id },
          handlers: [[getOrganizationQuery, jest.fn().mockRejectedValueOnce()]],
        });

        expect(findAlert().exists()).toBe(false);

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(FETCH_ORGANIZATION_ERROR);
      });
    });
  });

  describe('when listbox bottom is reached and there are more organizations to load', () => {
    const [firstPage, secondPage] = chunk(nodes, Math.ceil(nodes.length / 2));
    const getCurrentUserOrganizationsQueryMultiplePagesHandler = jest
      .fn()
      .mockResolvedValueOnce({
        data: {
          currentUser: {
            id: 'gid://gitlab/User/1',
            __typename: 'CurrentUser',
            organizations: { nodes: firstPage, pageInfo: pageInfoMultiplePages },
          },
        },
      })
      .mockResolvedValueOnce({
        data: {
          currentUser: {
            id: 'gid://gitlab/User/1',
            __typename: 'CurrentUser',
            organizations: { nodes: secondPage, pageInfo: pageInfoEmpty },
          },
        },
      });

    beforeEach(async () => {
      createComponent({
        handlers: [
          [getCurrentUserOrganizationsQuery, getCurrentUserOrganizationsQueryMultiplePagesHandler],
          [getOrganizationQuery, getOrganizationQueryHandler],
        ],
      });
      openListbox();
      await waitForPromises();

      findListbox().vm.$emit('bottom-reached');
      await waitForPromises();
    });

    it('calls graphQL query correct `after` variable', () => {
      expect(getCurrentUserOrganizationsQueryMultiplePagesHandler).toHaveBeenCalledWith({
        search: '',
        after: pageInfoMultiplePages.endCursor,
        first: DEFAULT_PER_PAGE,
      });
      expect(findListbox().props('infiniteScroll')).toBe(false);
    });
  });

  describe('when listbox is searched', () => {
    const searchTerm = 'foo';

    beforeEach(async () => {
      createComponent();
      openListbox();
      await waitForPromises();

      findListbox().vm.$emit('search', searchTerm);
    });

    it('calls graphQL query with search term', () => {
      expect(getCurrentUserOrganizationsQueryHandler).toHaveBeenCalledWith({
        search: searchTerm,
        after: null,
        first: DEFAULT_PER_PAGE,
      });
    });
  });

  it('shows an error when fetching organizations fails', async () => {
    createComponent({
      handlers: [[getCurrentUserOrganizationsQuery, jest.fn().mockRejectedValueOnce()]],
    });
    openListbox();
    expect(findAlert().exists()).toBe(false);

    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toBe(FETCH_ORGANIZATIONS_ERROR);
  });

  it('forwards events to the parent scope via `v-on="$listeners"`', () => {
    createComponent();
    findEntitySelect().vm.$emit('input');

    expect(handleInput).toHaveBeenCalledTimes(1);
  });

  describe('when query and queryPath props are passed', () => {
    const getOrganizationsQueryHandler = jest.fn().mockResolvedValue(organizationsGraphQlResponse);

    beforeEach(async () => {
      createComponent({
        props: {
          query: getOrganizationsQuery,
          queryPath: 'organizations',
        },
        handlers: [
          [getOrganizationsQuery, getOrganizationsQueryHandler],
          [getOrganizationQuery, getOrganizationQueryHandler],
        ],
      });
      openListbox();
      await waitForPromises();
    });

    it('uses passed GraphQL query', () => {
      const expectedItems = organizationsGraphQlResponse.data.organizations.nodes.map((node) => ({
        ...node,
        text: node.name,
        value: getIdFromGraphQLId(node.id),
      }));

      expect(findListbox().props('items')).toEqual(expectedItems);
    });
  });
});
