import { GlLoadingIcon, GlButton, GlEmptyState } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import { getProjectRepositoryHealth } from '~/rest_api';
import RepositoryHealthDetailsSection from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_section.vue';
import RepositoryHealthDetailsHeader from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_header.vue';
import RepositoryHealthDetailsStorageBreakdown from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_storage_breakdown.vue';
import RepositoryHealthDetailsPerformanceOptimizations from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_performance_optimizations.vue';
import RepositoryHealthDetailsMaintenanceStatus from '~/usage_quotas/storage/project/components/repository_health_details/repository_health_details_maintenance_status.vue';
import {
  MOCK_REPOSITORY,
  MOCK_REPOSITORY_HEALTH_DETAILS,
} from 'jest/usage_quotas/storage/mock_data';

jest.mock('~/rest_api', () => ({
  getProjectRepositoryHealth: jest.fn(),
}));

jest.mock('~/alert');

const MOCK_NOT_FOUND_ERROR = Object.assign(new Error('404 Health Report Not Found'), {
  response: { status: 404 },
});
const MOCK_SERVER_ERROR = Object.assign(new Error('500 Server Error'), {
  response: { status: 500 },
});

const mockRepositoryHealthDetailsAPIResponse = () => {
  getProjectRepositoryHealth.mockResolvedValueOnce({
    data: MOCK_REPOSITORY_HEALTH_DETAILS,
  });
};

const mockRepositoryHealthDetailsAPIRejectNotFound = () => {
  getProjectRepositoryHealth.mockRejectedValueOnce(MOCK_NOT_FOUND_ERROR);
};

const mockRepositoryHealthDetailsAPIRejectServerError = () => {
  getProjectRepositoryHealth.mockRejectedValueOnce(MOCK_SERVER_ERROR);
};

describe('RepositoryHealthDetailsSection', () => {
  let wrapper;

  const defaultProps = {
    repository: MOCK_REPOSITORY,
  };

  const createComponent = ({
    props = {},
    mockApiResponse = mockRepositoryHealthDetailsAPIResponse,
  } = {}) => {
    mockApiResponse();

    wrapper = shallowMountExtended(RepositoryHealthDetailsSection, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlEmptyStateButton = () => findGlEmptyState().findComponent(GlButton);
  const findRepositoryHealthDetailsHeader = () =>
    wrapper.findComponent(RepositoryHealthDetailsHeader);
  const findRepositoryHealthDetailsStorageBreakdown = () =>
    wrapper.findComponent(RepositoryHealthDetailsStorageBreakdown);
  const findRepositoryHealthDetailsPerformanceOptimizations = () =>
    wrapper.findComponent(RepositoryHealthDetailsPerformanceOptimizations);
  const findRepositoryHealthDetailsMaintenanceStatus = () =>
    wrapper.findComponent(RepositoryHealthDetailsMaintenanceStatus);

  describe('when no projectId exists', () => {
    beforeEach(async () => {
      createComponent({ props: { repository: null } });
      await waitForPromises();
    });

    it('does not call the API and renders error text', () => {
      expect(getProjectRepositoryHealth).not.toHaveBeenCalled();
      expect(wrapper.text()).toBe('Failed to parse Project ID from Repository.');
    });
  });

  describe('when health report is loading', () => {
    it('calls API and renders loading icon', () => {
      createComponent();

      expect(getProjectRepositoryHealth).toHaveBeenCalledWith(
        getIdFromGraphQLId(MOCK_REPOSITORY.project.id),
        {},
      );
      expect(findGlLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when no health report is returned', () => {
    beforeEach(async () => {
      createComponent({ mockApiResponse: mockRepositoryHealthDetailsAPIRejectNotFound });
      await waitForPromises();
    });

    it('calls API correctly', () => {
      expect(getProjectRepositoryHealth).toHaveBeenCalledWith(
        getIdFromGraphQLId(MOCK_REPOSITORY.project.id),
        {},
      );
    });

    it('does not call createAlert', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('renders empty state with correct data', () => {
      expect(findGlEmptyState().exists()).toBe(true);
      expect(findGlEmptyState().props()).toStrictEqual(
        expect.objectContaining({
          title: 'Repository Health report was not found',
          description: 'You can generate a new report at any time by clicking the button below.',
          illustrationName: 'status-nothing-md',
        }),
      );
    });

    it('renders empty state generate button that calls api with generate param when clicked', async () => {
      expect(findGlEmptyStateButton().text()).toBe('Generate Report');

      findGlEmptyStateButton().vm.$emit('click');
      await nextTick();

      expect(getProjectRepositoryHealth).toHaveBeenCalledWith(
        getIdFromGraphQLId(MOCK_REPOSITORY.project.id),
        { generate: true },
      );
    });
  });

  describe('when health report is returned', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('calls API correctly', () => {
      expect(getProjectRepositoryHealth).toHaveBeenCalledWith(
        getIdFromGraphQLId(MOCK_REPOSITORY.project.id),
        {},
      );
    });

    it('renders RepositoryHealthDetailsHeader with correct props', () => {
      expect(findRepositoryHealthDetailsHeader().props('healthDetails')).toEqual(
        MOCK_REPOSITORY_HEALTH_DETAILS,
      );
    });

    it('calls fetchRepositoryHealth with generate param when header emits regenerate-report', async () => {
      findRepositoryHealthDetailsHeader().vm.$emit('regenerate-report');
      await nextTick();

      expect(getProjectRepositoryHealth).toHaveBeenCalledWith(
        getIdFromGraphQLId(MOCK_REPOSITORY.project.id),
        { generate: true },
      );
    });

    it('renders RepositoryHealthDetailsStorageBreakdown with correct props', () => {
      expect(findRepositoryHealthDetailsStorageBreakdown().props('healthDetails')).toEqual(
        MOCK_REPOSITORY_HEALTH_DETAILS,
      );
    });

    it('renders RepositoryHealthDetailsPerformanceOptimizations with correct props', () => {
      expect(findRepositoryHealthDetailsPerformanceOptimizations().props('healthDetails')).toEqual(
        MOCK_REPOSITORY_HEALTH_DETAILS,
      );
    });

    it('renders RepositoryHealthDetailsMaintenanceStatus with correct props', () => {
      expect(findRepositoryHealthDetailsMaintenanceStatus().props('healthDetails')).toEqual(
        MOCK_REPOSITORY_HEALTH_DETAILS,
      );
    });
  });

  describe('when health report returns an error', () => {
    beforeEach(async () => {
      createComponent({ mockApiResponse: mockRepositoryHealthDetailsAPIRejectServerError });
      await waitForPromises();
    });

    it('calls API correctly', () => {
      expect(getProjectRepositoryHealth).toHaveBeenCalledWith(
        getIdFromGraphQLId(MOCK_REPOSITORY.project.id),
        {},
      );
    });

    it('calls createAlert when response fails', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to fetch repository health, try again later.',
        captureError: true,
        error: MOCK_SERVER_ERROR,
      });
    });
  });
});
