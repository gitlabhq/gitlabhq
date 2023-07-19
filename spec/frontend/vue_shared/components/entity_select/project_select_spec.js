import { GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import ProjectSelect from '~/vue_shared/components/entity_select/project_select.vue';
import EntitySelect from '~/vue_shared/components/entity_select/entity_select.vue';
import {
  PROJECT_TOGGLE_TEXT,
  PROJECT_HEADER_TEXT,
  FETCH_PROJECTS_ERROR,
  FETCH_PROJECT_ERROR,
} from '~/vue_shared/components/entity_select/constants';
import waitForPromises from 'helpers/wait_for_promises';

describe('ProjectSelect', () => {
  let wrapper;
  let mock;

  // Stubs
  const GlAlert = {
    template: '<div><slot /></div>',
  };

  // Props
  const label = 'label';
  const inputName = 'inputName';
  const inputId = 'inputId';
  const groupId = '22';
  const userId = '1';

  // Mocks
  const apiVersion = 'v4';
  const projectMock = {
    name_with_namespace: 'selectedProject',
    id: '1',
  };
  const projectsEndpoint = `/api/${apiVersion}/projects.json`;
  const groupProjectEndpoint = `/api/${apiVersion}/groups/${groupId}/projects.json`;
  const userProjectEndpoint = `/api/${apiVersion}/users/${userId}/projects`;
  const projectEndpoint = `/api/${apiVersion}/projects/${projectMock.id}`;

  // Finders
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findEntitySelect = () => wrapper.findComponent(EntitySelect);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const handleInput = jest.fn();

  // Helpers
  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(ProjectSelect, {
      propsData: {
        label,
        inputName,
        inputId,
        groupId,
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
    gon.api_version = apiVersion;
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('renders HTML label when hasHtmlLabel is true', () => {
    const testid = 'html-label';
    createComponent({
      props: {
        label: `<div data-testid="${testid}" />`,
        hasHtmlLabel: true,
      },
    });

    expect(wrapper.findByTestId(testid).exists()).toBe(true);
  });

  describe('entity_select props', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      prop                   | expectedValue
      ${'label'}             | ${label}
      ${'inputName'}         | ${inputName}
      ${'inputId'}           | ${inputId}
      ${'defaultToggleText'} | ${PROJECT_TOGGLE_TEXT}
      ${'headerText'}        | ${PROJECT_HEADER_TEXT}
      ${'clearable'}         | ${true}
      ${'block'}             | ${false}
    `('passes the $prop prop to entity-select', ({ prop, expectedValue }) => {
      expect(findEntitySelect().props(prop)).toBe(expectedValue);
    });
  });

  describe('on mount', () => {
    it('fetches projects when the listbox is opened', async () => {
      createComponent();
      await waitForPromises();

      expect(mock.history.get).toHaveLength(0);

      openListbox();
      await waitForPromises();

      expect(mock.history.get).toHaveLength(1);
      expect(mock.history.get[0].url).toBe(groupProjectEndpoint);
      expect(mock.history.get[0].params).toEqual({
        include_subgroups: false,
        order_by: 'similarity',
        per_page: 20,
        search: '',
        simple: true,
        with_shared: true,
      });
    });

    it('includes projects from subgroups if includeSubgroups is true', async () => {
      createComponent({
        props: {
          includeSubgroups: true,
        },
      });
      openListbox();
      await waitForPromises();

      expect(mock.history.get[0].params.include_subgroups).toBe(true);
    });

    it('does not include shared projects if withShared prop is false', async () => {
      createComponent({
        props: {
          withShared: false,
        },
      });
      openListbox();
      await waitForPromises();

      expect(mock.history.get[0].params.with_shared).toBe(false);
    });

    it('fetches projects globally if no group ID is provided', async () => {
      createComponent({
        props: {
          groupId: null,
        },
      });
      openListbox();
      await waitForPromises();

      expect(mock.history.get[0].url).toBe(projectsEndpoint);
      expect(mock.history.get[0].params).toEqual({
        membership: false,
        order_by: 'similarity',
        per_page: 20,
        search: '',
        simple: true,
      });
    });

    it('restricts search to owned projects if membership is true', async () => {
      createComponent({
        props: {
          groupId: null,
          membership: true,
        },
      });
      openListbox();
      await waitForPromises();

      expect(mock.history.get[0].params.membership).toBe(true);
    });

    it("fetches the user's projects if a user ID is provided", async () => {
      createComponent({
        props: {
          groupId: null,
          userId,
        },
      });
      openListbox();
      await waitForPromises();

      expect(mock.history.get[0].url).toBe(userProjectEndpoint);
      expect(mock.history.get[0].params).toEqual({
        per_page: 20,
        search: '',
        with_shared: true,
        include_subgroups: false,
      });
    });

    it.each([null, groupId])(
      'fetches with the provided sort key when groupId is %s',
      async (groupIdProp) => {
        const orderBy = 'last_activity_at';
        createComponent({
          props: {
            groupId: groupIdProp,
            orderBy,
          },
        });
        openListbox();
        await waitForPromises();

        expect(mock.history.get[0].params.order_by).toBe(orderBy);
      },
    );

    describe('with an initial selection', () => {
      it("fetches the initially selected value's name", async () => {
        mock.onGet(projectEndpoint).reply(HTTP_STATUS_OK, projectMock);
        createComponent({ props: { initialSelection: projectMock.id } });
        await waitForPromises();

        expect(mock.history.get).toHaveLength(1);
        expect(findListbox().props('toggleText')).toBe(projectMock.name_with_namespace);
      });

      it('show an error if fetching the individual project fails', async () => {
        mock
          .onGet(groupProjectEndpoint)
          .reply(HTTP_STATUS_OK, [{ full_name: 'notTheSelectedProject', id: '2' }]);
        mock.onGet(projectEndpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        createComponent({ props: { initialSelection: projectMock.id } });

        expect(findAlert().exists()).toBe(false);

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(FETCH_PROJECT_ERROR);
      });
    });
  });

  it('shows an error when fetching projects fails', async () => {
    mock.onGet(groupProjectEndpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    createComponent();
    openListbox();
    expect(findAlert().exists()).toBe(false);

    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toBe(FETCH_PROJECTS_ERROR);
  });

  it('forwards events to the parent scope via `v-on="$listeners"`', () => {
    createComponent();
    findEntitySelect().vm.$emit('input');

    expect(handleInput).toHaveBeenCalledTimes(1);
  });
});
