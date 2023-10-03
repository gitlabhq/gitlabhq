import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import resolvers from '~/organizations/shared/graphql/resolvers';
import { organizations } from '~/organizations/mock_data';
import organizationsQuery from '~/organizations/index/graphql/organizations.query.graphql';
import OrganizationsView from '~/organizations/index/components/organizations_view.vue';
import OrganizationsList from '~/organizations/index/components/organizations_list.vue';
import { MOCK_NEW_ORG_URL, MOCK_ORG_EMPTY_STATE_SVG } from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('OrganizationsView', () => {
  let wrapper;
  let mockApollo;

  const createComponent = (mockResolvers = resolvers) => {
    mockApollo = createMockApollo([[organizationsQuery, mockResolvers]]);

    wrapper = shallowMount(OrganizationsView, {
      apolloProvider: mockApollo,
      provide: {
        newOrganizationUrl: MOCK_NEW_ORG_URL,
        organizationsEmptyStateSvgPath: MOCK_ORG_EMPTY_STATE_SVG,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  const findGlLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findOrganizationsList = () => wrapper.findComponent(OrganizationsList);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('when API call is loading', () => {
    beforeEach(() => {
      const mockResolvers = jest.fn().mockReturnValue(new Promise(() => {}));

      createComponent(mockResolvers);
    });

    it('renders loading icon', () => {
      expect(findGlLoading().exists()).toBe(true);
    });

    it('does not render organizations list', () => {
      expect(findOrganizationsList().exists()).toBe(false);
    });

    it('does not render empty state', () => {
      expect(findGlEmptyState().exists()).toBe(false);
    });
  });

  describe('when API returns successful with results', () => {
    beforeEach(async () => {
      const mockResolvers = jest.fn().mockResolvedValue({
        data: { currentUser: { id: 1, organizations: { nodes: organizations } } },
      });

      createComponent(mockResolvers);
      await waitForPromises();
    });

    it('does not render loading icon', () => {
      expect(findGlLoading().exists()).toBe(false);
    });

    it('renders organizations list', () => {
      expect(findOrganizationsList().exists()).toBe(true);
    });

    it('does not render empty state', () => {
      expect(findGlEmptyState().exists()).toBe(false);
    });
  });

  describe('when API returns successful without results', () => {
    beforeEach(async () => {
      const mockResolvers = jest
        .fn()
        .mockResolvedValue({ data: { currentUser: { id: 1, organizations: { nodes: [] } } } });

      createComponent(mockResolvers);
      await waitForPromises();
    });

    it('does not render loading icon', () => {
      expect(findGlLoading().exists()).toBe(false);
    });

    it('does not render organizations list', () => {
      expect(findOrganizationsList().exists()).toBe(false);
    });

    it('does render empty state with correct SVG and URL', () => {
      expect(findGlEmptyState().exists()).toBe(true);
      expect(findGlEmptyState().attributes('svgpath')).toBe(MOCK_ORG_EMPTY_STATE_SVG);
      expect(findGlEmptyState().attributes('primarybuttonlink')).toBe(MOCK_NEW_ORG_URL);
    });
  });

  describe('when API returns error', () => {
    const error = new Error();

    beforeEach(async () => {
      const mockResolvers = jest.fn().mockRejectedValue(error);

      createComponent(mockResolvers);
      await waitForPromises();
    });

    it('creates a flash message', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message:
          'An error occurred loading user organizations. Please refresh the page to try again.',
        error,
        captureError: true,
      });
    });
  });
});
