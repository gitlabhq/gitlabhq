import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { chunk } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationSelect from '~/vue_shared/components/entity_select/organization_select.vue';
import EntitySelect from '~/vue_shared/components/entity_select/entity_select.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import {
  ORGANIZATION_TOGGLE_TEXT,
  ORGANIZATION_HEADER_TEXT,
  FETCH_ORGANIZATIONS_ERROR,
  FETCH_ORGANIZATION_ERROR,
} from '~/vue_shared/components/entity_select/constants';
import getCurrentUserOrganizationsQuery from '~/organizations/shared/graphql/queries/organizations.query.graphql';
import getOrganizationQuery from '~/organizations/shared/graphql/queries/organization.query.graphql';
import { organizations as nodes, pageInfo, pageInfoEmpty } from '~/organizations/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

describe('OrganizationSelect', () => {
  let wrapper;
  let mockApollo;

  // Mocks
  const [organization] = nodes;
  const organizations = {
    nodes,
    pageInfo,
  };

  // Stubs
  const GlAlert = {
    template: '<div><slot /></div>',
  };

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
  const getCurrentUserOrganizationsQueryHandler = jest.fn().mockResolvedValue({
    data: { currentUser: { id: 'gid://gitlab/User/1', __typename: 'CurrentUser', organizations } },
  });
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

    wrapper = shallowMountExtended(OrganizationSelect, {
      apolloProvider: mockApollo,
      propsData: {
        label,
        description,
        inputName,
        inputId,
        toggleClass,
        ...props,
      },
      stubs: {
        GlAlert,
        EntitySelect,
      },
      listeners: {
        input: handleInput,
      },
    });
  };
  const openListbox = () => findListbox().vm.$emit('shown');

  afterEach(() => {
    mockApollo = null;
  });

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
    `('passes the $prop prop to entity-select', ({ prop, expectedValue }) => {
      expect(findEntitySelect().props(prop)).toBe(expectedValue);
    });
  });

  describe('on mount', () => {
    it('fetches organizations when the listbox is opened', async () => {
      createComponent();
      await waitForPromises();

      openListbox();
      await waitForPromises();
      expect(findListbox().props('items')).toEqual([
        { text: nodes[0].name, value: 1 },
        { text: nodes[1].name, value: 2 },
        { text: nodes[2].name, value: 3 },
      ]);
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
          handlers: [[getOrganizationQuery, jest.fn().mockRejectedValueOnce(new Error())]],
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
            organizations: { nodes: firstPage, pageInfo },
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
      await nextTick();
      await waitForPromises();
    });

    it('calls graphQL query correct `after` variable', () => {
      expect(getCurrentUserOrganizationsQueryMultiplePagesHandler).toHaveBeenCalledWith({
        after: pageInfo.endCursor,
        first: DEFAULT_PER_PAGE,
      });
      expect(findListbox().props('infiniteScroll')).toBe(false);
    });
  });

  it('shows an error when fetching organizations fails', async () => {
    createComponent({
      handlers: [[getCurrentUserOrganizationsQuery, jest.fn().mockRejectedValueOnce(new Error())]],
    });
    await waitForPromises();

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
});
