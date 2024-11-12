import { GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import EntitySelect from '~/vue_shared/components/entity_select/entity_select.vue';
import {
  GROUP_TOGGLE_TEXT,
  GROUP_HEADER_TEXT,
  FETCH_GROUPS_ERROR,
  FETCH_GROUP_ERROR,
} from '~/vue_shared/components/entity_select/constants';
import waitForPromises from 'helpers/wait_for_promises';

describe('GroupSelect', () => {
  let wrapper;
  let mock;

  // Mocks
  const groupMock = {
    full_name: 'selectedGroup',
    id: '1',
  };
  const groupEndpoint = `/api/undefined/groups/${groupMock.id}`;

  // Stubs
  const GlAlert = {
    template: '<div><slot /></div>',
  };

  // Props
  const label = 'label';
  const description = 'description';
  const inputName = 'inputName';
  const inputId = 'inputId';

  // Finders
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findEntitySelect = () => wrapper.findComponent(EntitySelect);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const handleInput = jest.fn();

  // Helpers
  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(GroupSelect, {
      propsData: {
        label,
        description,
        inputName,
        inputId,
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

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
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
      ${'defaultToggleText'} | ${GROUP_TOGGLE_TEXT}
      ${'headerText'}        | ${GROUP_HEADER_TEXT}
    `('passes the $prop prop to entity-select', ({ prop, expectedValue }) => {
      expect(findEntitySelect().props(prop)).toBe(expectedValue);
    });
  });

  describe('on mount', () => {
    it('fetches groups when the listbox is opened', async () => {
      createComponent();
      await waitForPromises();

      expect(mock.history.get).toHaveLength(0);

      openListbox();
      await waitForPromises();

      expect(mock.history.get).toHaveLength(1);
    });

    describe('with an initial selection', () => {
      it("fetches the initially selected value's name", async () => {
        mock.onGet(groupEndpoint).reply(HTTP_STATUS_OK, groupMock);
        createComponent({ props: { initialSelection: groupMock.id } });
        await waitForPromises();

        expect(mock.history.get).toHaveLength(1);
        expect(findListbox().props('toggleText')).toBe(groupMock.full_name);
      });

      it('show an error if fetching the individual group fails', async () => {
        mock
          .onGet('/api/undefined/groups.json')
          .reply(HTTP_STATUS_OK, [{ full_name: 'notTheSelectedGroup', id: '2' }]);
        mock.onGet(groupEndpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        createComponent({ props: { initialSelection: groupMock.id } });

        expect(findAlert().exists()).toBe(false);

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(FETCH_GROUP_ERROR);
      });
    });
  });

  it('shows an error when fetching groups fails', async () => {
    mock.onGet('/api/undefined/groups.json').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    createComponent();
    openListbox();
    expect(findAlert().exists()).toBe(false);

    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toBe(FETCH_GROUPS_ERROR);
  });

  it('forwards events to the parent scope via `v-on="$listeners"`', () => {
    createComponent();
    findEntitySelect().vm.$emit('input');

    expect(handleInput).toHaveBeenCalledTimes(1);
  });
});
