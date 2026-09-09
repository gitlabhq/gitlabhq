import MockAdapter from 'axios-mock-adapter';
import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import PipelinesWidget from '~/homepage/components/pipelines_widget.vue';
import BaseWidget from '~/homepage/components/base_widget.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_PIPELINES,
} from '~/homepage/tracking_constants';

jest.mock('~/sentry/sentry_browser_wrapper', () => ({
  captureException: jest.fn(),
}));

describe('PipelinesWidget', () => {
  let wrapper;
  let mockAxios;

  const PIPELINES_API_URL = '/api/v4/pipelines';

  const mockPipelines = [
    {
      id: 1001,
      iid: 51,
      project_id: 7,
      sha: '0ec9e58fdfca6cdd6652c083c9edb53abc0bad52',
      ref: 'main',
      status: 'success',
      source: 'merge_request_event',
      created_at: '2025-06-21T09:15:00Z',
      updated_at: '2025-06-21T09:25:00Z',
      web_url: '/project-a/-/pipelines/1001',
      name: 'Build pipeline',
      detailed_status: {
        icon: 'status_success',
        text: 'Passed',
        label: 'passed',
        group: 'success',
      },
      project: {
        id: 7,
        name: 'Project A',
        name_with_namespace: 'Group A / Project A',
        path_with_namespace: 'group-a/project-a',
      },
    },
    {
      id: 1000,
      iid: 50,
      project_id: 8,
      sha: '1fc9e58fdfca6cdd6652c083c9edb53abc0bad52',
      ref: 'feature-branch',
      status: 'failed',
      source: 'merge_request_event',
      created_at: '2025-06-20T10:00:00Z',
      updated_at: '2025-06-20T10:30:00Z',
      web_url: '/project-b/-/pipelines/1000',
      name: null,
      detailed_status: {
        icon: 'status_warning',
        text: 'Warning',
        label: 'failed (allowed to fail)',
        group: 'failed-with-warnings',
      },
      project: {
        id: 8,
        name: 'Project B',
        name_with_namespace: 'Group B / Project B',
        path_with_namespace: 'group-b/project-b',
      },
      merge_request: {
        iid: 48602,
        title: 'Add rate limiting to the public API',
        web_url: '/project-b/-/merge_requests/48602',
      },
    },
  ];

  const createComponent = () => {
    wrapper = shallowMountExtended(PipelinesWidget);
  };

  const findSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findErrorMessage = () => wrapper.findByTestId('pipelines-widget-error');
  const findEmptyState = () => wrapper.findByTestId('pipelines-widget-empty-state');
  const findPipelinesList = () => wrapper.find('ul');
  const findPipelineLinks = () => findPipelinesList().findAll('a');
  const findCiIcons = () => wrapper.findAllComponents(CiIcon);
  const findTimeAgoTooltips = () => wrapper.findAllComponents(TimeAgoTooltip);
  const findTooltipComponents = () => wrapper.findAllComponents(TooltipOnTruncate);

  beforeEach(() => {
    window.gon = { api_version: 'v4' };
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('loading state', () => {
    beforeEach(() => {
      mockAxios.onGet(PIPELINES_API_URL).reply(HTTP_STATUS_OK, mockPipelines);
    });

    it('shows skeleton loaders while fetching data', () => {
      createComponent();

      expect(findSkeletonLoaders()).toHaveLength(6);
      expect(findPipelinesList().exists()).toBe(false);
    });

    it('hides skeleton loaders after data is fetched', async () => {
      createComponent();
      await waitForPromises();

      expect(findSkeletonLoaders()).toHaveLength(0);
      expect(findPipelinesList().exists()).toBe(true);
    });
  });

  describe('error state', () => {
    beforeEach(async () => {
      mockAxios.onGet(PIPELINES_API_URL).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent();
      await waitForPromises();
    });

    it('shows an error message when the request fails', () => {
      expect(findErrorMessage().text()).toBe(
        'Your pipelines are not available. Please refresh the page to try again.',
      );
    });

    it('captures the error with Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
    });

    it('does not show the pipelines list', () => {
      expect(findPipelinesList().exists()).toBe(false);
    });
  });

  describe('empty state', () => {
    it('shows the empty state when there are no pipelines', async () => {
      mockAxios.onGet(PIPELINES_API_URL).reply(HTTP_STATUS_OK, []);
      createComponent();
      await waitForPromises();

      expect(findEmptyState().text()).toBe('Pipelines for your merge requests will appear here.');
      expect(findPipelinesList().exists()).toBe(false);
    });
  });

  describe('pipelines rendering', () => {
    beforeEach(async () => {
      mockAxios.onGet(PIPELINES_API_URL).reply(HTTP_STATUS_OK, mockPipelines);
      createComponent();
      await waitForPromises();
    });

    it('overfetches merge request pipelines to absorb visibility filtering', () => {
      expect(mockAxios.history.get).toHaveLength(1);
      expect(mockAxios.history.get[0].params).toEqual({
        per_page: 20,
        source: 'merge_request_event',
      });
    });

    it('renders a link for each pipeline', () => {
      const links = findPipelineLinks();

      expect(links).toHaveLength(2);
      expect(links.at(0).attributes('href')).toBe('/project-a/-/pipelines/1001');
      expect(links.at(1).attributes('href')).toBe('/project-b/-/pipelines/1000');
    });

    it('renders the pipeline name as the title when there is no merge request', () => {
      expect(findTooltipComponents().at(0).props('title')).toBe('Build pipeline');
    });

    it('uses the merge request title as the title', () => {
      expect(findTooltipComponents().at(1).props('title')).toBe(
        'Add rate limiting to the public API',
      );
    });

    it('renders the status icons from the detailed status', () => {
      const icons = findCiIcons();

      expect(icons.at(0).props('status')).toMatchObject({ icon: 'status_success', text: 'Passed' });
      expect(icons.at(0).props('useLink')).toBe(false);
      expect(icons.at(1).props('status')).toMatchObject({
        icon: 'status_warning',
        text: 'Warning',
      });
    });

    it('renders the project name with its namespace, like to-do items', () => {
      const links = findPipelineLinks();

      expect(links.at(0).text()).toContain('Group A / Project A');
      expect(links.at(1).text()).toContain('Group B / Project B');
    });

    it('does not render the pipeline id', () => {
      expect(findPipelinesList().text()).not.toContain('#1001');
    });

    it('renders the created at timestamps', () => {
      const timeAgos = findTimeAgoTooltips();

      expect(timeAgos.at(0).props('time')).toBe('2025-06-21T09:15:00Z');
      expect(timeAgos.at(1).props('time')).toBe('2025-06-20T10:00:00Z');
    });
  });

  describe('when the API returns more pipelines than the widget shows', () => {
    beforeEach(async () => {
      const pipelines = Array.from({ length: 7 }, (_, i) => ({
        ...mockPipelines[0],
        id: 2000 + i,
      }));
      mockAxios.onGet(PIPELINES_API_URL).reply(HTTP_STATUS_OK, pipelines);
      createComponent();
      await waitForPromises();
    });

    it('renders only the first six', () => {
      expect(findPipelineLinks()).toHaveLength(6);
    });
  });

  describe('when the pipeline has no merge request and no name', () => {
    beforeEach(async () => {
      mockAxios
        .onGet(PIPELINES_API_URL)
        .reply(HTTP_STATUS_OK, [{ ...mockPipelines[1], merge_request: undefined }]);
      createComponent();
      await waitForPromises();
    });

    it('falls back to the ref as the title', () => {
      expect(findTooltipComponents().at(0).props('title')).toBe('feature-branch');
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      mockAxios.onGet(PIPELINES_API_URL).reply(HTTP_STATUS_OK, mockPipelines);
      createComponent();
      await waitForPromises();
    });

    it('tracks clicks on a pipeline link', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const link = findPipelineLinks().at(0);

      link.element.addEventListener('click', (e) => e.preventDefault());
      await link.trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        { label: TRACKING_LABEL_PIPELINES },
        undefined,
      );
    });
  });

  describe('refresh functionality', () => {
    it('refetches the pipelines on becoming visible again', async () => {
      mockAxios.onGet(PIPELINES_API_URL).reply(HTTP_STATUS_OK, mockPipelines);
      createComponent();
      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(1);

      wrapper.findComponent(BaseWidget).vm.$emit('visible');
      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(2);
    });
  });
});
