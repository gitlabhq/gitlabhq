import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { Tracker } from '~/tracking/tracker';
import waitForPromises from 'helpers/wait_for_promises';
import {
  EVENT_VIEW_DASHBOARD,
  scopeTypeOf,
  trackDashboardEvent,
} from '~/explore/analytics_dashboards/tracking';

jest.mock('~/sentry/sentry_browser_wrapper');

const TRACK_EVENTS_URL = '/api/v4/usage_data/track_events';

const group = { id: 'gid://gitlab/Group/11', fullPath: 'gitlab-org', type: 'Group' };
const otherGroup = { id: 'gid://gitlab/Group/12', fullPath: 'gitlab-com', type: 'Group' };
const project = { id: 'gid://gitlab/Project/21', fullPath: 'gitlab-org/gitlab', type: 'Project' };

describe('Explore analytics dashboards tracking', () => {
  describe('scopeTypeOf', () => {
    it.each`
      namespaces             | expected
      ${[group]}             | ${'group'}
      ${[group, otherGroup]} | ${'group'}
      ${[project]}           | ${'project'}
      ${[group, project]}    | ${'mixed'}
    `('returns $expected', ({ namespaces, expected }) => {
      expect(scopeTypeOf(namespaces)).toBe(expected);
    });
  });

  describe('trackDashboardEvent', () => {
    let mock;

    const postedEvents = () => JSON.parse(mock.history.post[0].data).events;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onPost(TRACK_EVENTS_URL).reply(HTTP_STATUS_OK);
      window.gon = { ...window.gon, current_user_id: 1, api_version: 'v4' };
      jest.spyOn(Tracker, 'enabled').mockReturnValue(true);
    });

    afterEach(() => {
      mock.restore();
      window.gl = undefined;
    });

    it('sends one event per selected namespace in a single request', async () => {
      trackDashboardEvent(EVENT_VIEW_DASHBOARD, [group, project], {
        label: 'dap_impact',
        property: 'Overview',
      });
      await waitForPromises();

      expect(mock.history.post).toHaveLength(1);
      expect(postedEvents()).toEqual([
        expect.objectContaining({ event: EVENT_VIEW_DASHBOARD, namespace_id: 11 }),
        expect.objectContaining({ event: EVENT_VIEW_DASHBOARD, project_id: 21 }),
      ]);
    });

    it('gives every event in the batch the same properties and view_id', async () => {
      trackDashboardEvent(EVENT_VIEW_DASHBOARD, [group, otherGroup], { label: 'dap_impact' });
      await waitForPromises();

      const [first, second] = postedEvents().map((event) => event.additional_properties);

      expect(first).toEqual({
        label: 'dap_impact',
        view_id: expect.any(String),
        scope_count: 2,
        scope_type: 'group',
      });
      expect(second).toEqual(first);
    });

    it('gives each view its own view_id', async () => {
      trackDashboardEvent(EVENT_VIEW_DASHBOARD, [group], { label: 'dap_impact' });
      trackDashboardEvent(EVENT_VIEW_DASHBOARD, [group], { label: 'dap_impact' });
      await waitForPromises();

      const [first, second] = mock.history.post.map(
        ({ data }) => JSON.parse(data).events[0].additional_properties.view_id,
      );

      expect(first).toMatch(
        /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
      );
      expect(second).not.toBe(first);
    });

    it.each([true, false])(
      'sends to Snowplow only when the tracker is enabled (%s)',
      async (enabled) => {
        Tracker.enabled.mockReturnValue(enabled);

        trackDashboardEvent(EVENT_VIEW_DASHBOARD, [group]);
        await waitForPromises();

        expect(postedEvents()[0].send_to_snowplow).toBe(enabled);
      },
    );

    it('sends nothing without a signed-in user', async () => {
      window.gon.current_user_id = undefined;

      trackDashboardEvent(EVENT_VIEW_DASHBOARD, [group]);
      await waitForPromises();

      expect(mock.history.post).toHaveLength(0);
    });

    it('sends nothing when only Duo events may be sent', async () => {
      window.gl = { onlySendDuoEvents: true, duoEvents: [] };

      trackDashboardEvent(EVENT_VIEW_DASHBOARD, [group]);
      await waitForPromises();

      expect(mock.history.post).toHaveLength(0);
    });

    it('sends nothing without a selected namespace', async () => {
      trackDashboardEvent(EVENT_VIEW_DASHBOARD, []);
      await waitForPromises();

      expect(mock.history.post).toHaveLength(0);
    });

    it('reports a failed request to Sentry', async () => {
      mock.onPost(TRACK_EVENTS_URL).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      trackDashboardEvent(EVENT_VIEW_DASHBOARD, [group]);
      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });
});
