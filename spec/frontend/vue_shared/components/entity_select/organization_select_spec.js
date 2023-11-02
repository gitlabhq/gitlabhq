import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationSelect from '~/vue_shared/components/entity_select/organization_select.vue';
import EntitySelect from '~/vue_shared/components/entity_select/entity_select.vue';
import {
  ORGANIZATION_TOGGLE_TEXT,
  ORGANIZATION_HEADER_TEXT,
  FETCH_ORGANIZATIONS_ERROR,
  FETCH_ORGANIZATION_ERROR,
} from '~/vue_shared/components/entity_select/constants';
import resolvers from '~/organizations/shared/graphql/resolvers';
import organizationsQuery from '~/organizations/index/graphql/organizations.query.graphql';
import { organizations as organizationsMock } from '~/organizations/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

jest.useFakeTimers();

describe('OrganizationSelect', () => {
  let wrapper;
  let mockApollo;

  // Mocks
  const [organizationMock] = organizationsMock;

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

  const handleInput = jest.fn();

  // Helpers
  const createComponent = ({ props = {}, mockResolvers = resolvers, handlers } = {}) => {
    mockApollo = createMockApollo(
      handlers || [
        [
          organizationsQuery,
          jest.fn().mockResolvedValueOnce({
            data: { currentUser: { id: 1, organizations: { nodes: organizationsMock } } },
          }),
        ],
      ],
      mockResolvers,
    );

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
      await nextTick();
      jest.runAllTimers();
      await waitForPromises();

      openListbox();
      jest.runAllTimers();
      await waitForPromises();
      expect(findListbox().props('items')).toEqual([
        { text: organizationsMock[0].name, value: 1 },
        { text: organizationsMock[1].name, value: 2 },
        { text: organizationsMock[2].name, value: 3 },
      ]);
    });

    describe('with an initial selection', () => {
      it("fetches the initially selected value's name", async () => {
        createComponent({ props: { initialSelection: organizationMock.id } });
        await nextTick();
        jest.runAllTimers();
        await waitForPromises();

        expect(findListbox().props('toggleText')).toBe(organizationMock.name);
      });

      it('show an error if fetching initially selected fails', async () => {
        const mockResolvers = {
          Query: {
            organization: jest.fn().mockRejectedValueOnce(new Error()),
          },
        };

        createComponent({ props: { initialSelection: organizationMock.id }, mockResolvers });
        await nextTick();
        jest.runAllTimers();

        expect(findAlert().exists()).toBe(false);

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(FETCH_ORGANIZATION_ERROR);
      });
    });
  });

  it('shows an error when fetching organizations fails', async () => {
    createComponent({
      handlers: [[organizationsQuery, jest.fn().mockRejectedValueOnce(new Error())]],
    });
    await nextTick();
    jest.runAllTimers();
    await waitForPromises();

    openListbox();
    expect(findAlert().exists()).toBe(false);

    jest.runAllTimers();
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
