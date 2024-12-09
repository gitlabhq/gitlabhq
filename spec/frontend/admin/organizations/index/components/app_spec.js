import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import organizationsGraphQlResponse from 'test_fixtures/graphql/organizations/organizations.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { DEFAULT_PER_PAGE } from '~/api';
import organizationsQuery from '~/organizations/shared/graphql/queries/organizations.query.graphql';
import OrganizationsIndexApp from '~/admin/organizations/index/components/app.vue';
import OrganizationsView from '~/organizations/shared/components/organizations_view.vue';
import { MOCK_NEW_ORG_URL } from 'jest/organizations/shared/mock_data';
import { pageInfoEmpty } from 'jest/organizations/mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('AdminOrganizationsIndexApp', () => {
  let wrapper;
  let mockApollo;

  const {
    data: { organizations },
  } = organizationsGraphQlResponse;

  const organizationEmpty = {
    nodes: [],
    pageInfo: pageInfoEmpty,
  };

  const successHandler = jest.fn().mockResolvedValue(organizationsGraphQlResponse);

  const createComponent = ({ handler = successHandler, provide = {} } = {}) => {
    mockApollo = createMockApollo([[organizationsQuery, handler]]);

    wrapper = shallowMountExtended(OrganizationsIndexApp, {
      apolloProvider: mockApollo,
      provide: {
        newOrganizationUrl: MOCK_NEW_ORG_URL,
        canCreateOrganization: true,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    gon.features = { allowOrganizationCreation: true };
  });

  afterEach(() => {
    mockApollo = null;
  });

  // Finders
  const findOrganizationHeaderText = () => wrapper.findByRole('heading', { name: 'Organizations' });
  const findNewOrganizationButton = () => wrapper.findComponent(GlButton);
  const findOrganizationsView = () => wrapper.findComponent(OrganizationsView);

  // Assertions
  const itRendersHeaderText = () => {
    it('renders the header text', () => {
      expect(findOrganizationHeaderText().exists()).toBe(true);
    });
  };

  const itRendersNewOrganizationButton = () => {
    it('render new organization button with correct link', () => {
      expect(findNewOrganizationButton().attributes('href')).toBe(MOCK_NEW_ORG_URL);
    });
  };

  const itDoesNotRenderErrorMessage = () => {
    it('does not render an error message', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });
  };

  const itDoesNotRenderHeaderText = () => {
    it('does not render the header text', () => {
      expect(findOrganizationHeaderText().exists()).toBe(false);
    });
  };

  const itDoesNotRenderNewOrganizationButton = () => {
    it('does not render new organization button', () => {
      expect(findNewOrganizationButton().exists()).toBe(false);
    });
  };

  describe('when API call is loading', () => {
    beforeEach(() => {
      createComponent({ handler: jest.fn().mockReturnValue(new Promise(() => {})) });
    });

    itRendersHeaderText();
    itRendersNewOrganizationButton();
    itDoesNotRenderErrorMessage();

    it('renders the organizations view with loading prop set to true', () => {
      expect(findOrganizationsView().props('loading')).toBe(true);
    });
  });

  describe('when API call is successful', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    itRendersHeaderText();
    itRendersNewOrganizationButton();
    itDoesNotRenderErrorMessage();

    it('passes organizations to view component', () => {
      expect(findOrganizationsView().props()).toMatchObject({
        loading: false,
        organizations,
      });
    });
  });

  describe('when `canCreateOrganization` is false', () => {
    beforeEach(() => {
      createComponent({ provide: { canCreateOrganization: false } });
      return waitForPromises();
    });

    itDoesNotRenderNewOrganizationButton();
  });

  describe('when API call is successful and returns no organizations', () => {
    beforeEach(async () => {
      createComponent({
        handler: jest.fn().mockResolvedValue({
          data: {
            organizations: organizationEmpty,
          },
        }),
      });
      await waitForPromises();
    });

    itDoesNotRenderHeaderText();
    itDoesNotRenderNewOrganizationButton();
    itDoesNotRenderErrorMessage();

    it('renders view component with correct organizations and loading props', () => {
      expect(findOrganizationsView().props()).toMatchObject({
        loading: false,
        organizations: organizationEmpty,
      });
    });
  });

  describe('when API call is not successful', () => {
    const error = new Error();

    beforeEach(async () => {
      createComponent({ handler: jest.fn().mockRejectedValue(error) });
      await waitForPromises();
    });

    itDoesNotRenderHeaderText();
    itDoesNotRenderNewOrganizationButton();

    it('renders view component with correct organizations and loading props', () => {
      expect(findOrganizationsView().props()).toMatchObject({
        loading: false,
        organizations: {},
      });
    });

    it('renders error message', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred loading organizations. Please refresh the page to try again.',
        error,
        captureError: true,
      });
    });
  });

  describe('when view component emits `next` event', () => {
    const endCursor = 'mockEndCursor';

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('calls GraphQL query with correct pageInfo variables', async () => {
      findOrganizationsView().vm.$emit('next', endCursor);
      await waitForPromises();

      expect(successHandler).toHaveBeenCalledWith({
        first: DEFAULT_PER_PAGE,
        after: endCursor,
        last: null,
        before: null,
      });
    });
  });

  describe('when view component emits `prev` event', () => {
    const startCursor = 'mockStartCursor';

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('calls GraphQL query with correct pageInfo variables', async () => {
      findOrganizationsView().vm.$emit('prev', startCursor);
      await waitForPromises();

      expect(successHandler).toHaveBeenCalledWith({
        first: null,
        after: null,
        last: DEFAULT_PER_PAGE,
        before: startCursor,
      });
    });
  });
});
