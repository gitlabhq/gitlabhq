import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemErrorTracking from '~/work_items/components/work_item_error_tracking.vue';
import workItemErrorTrackingQuery from '~/work_items/graphql/work_item_error_tracking.query.graphql';
import {
  errorTrackingQueryResponseWithStackTrace,
  getErrorTrackingQueryResponse,
} from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('WorkItemErrorTracking component', () => {
  let wrapper;

  const queryHandler = jest.fn().mockResolvedValue(errorTrackingQueryResponseWithStackTrace);

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findStacktrace = () => wrapper.findComponent(Stacktrace);

  const createComponent = ({ handler = queryHandler } = {}) => {
    wrapper = shallowMount(WorkItemErrorTracking, {
      apolloProvider: createMockApollo([[workItemErrorTrackingQuery, handler]]),
      propsData: {
        fullPath: 'group/project',
        iid: '12345',
      },
    });
  };

  it('renders title', () => {
    createComponent();

    expect(findCrudComponent().props('title')).toBe('Stack trace');
  });

  it('makes call to stack trace endpoint', () => {
    createComponent();

    expect(queryHandler).toHaveBeenCalledWith({ fullPath: 'group/project', iid: '12345' });
  });

  it('renders Stacktrace component when we get data', async () => {
    createComponent();
    await waitForPromises();

    expect(findStacktrace().props('entries')).toEqual(
      errorTrackingQueryResponseWithStackTrace.data.namespace.workItem.widgets[0].stackTrace.nodes,
    );
  });

  it('renders error message when there is a query error', async () => {
    const error = new Error('error');
    createComponent({ handler: jest.fn().mockRejectedValue(error) });
    await waitForPromises();

    expect(findAlert().text()).toBe('Failed to load stack trace.');
    expect(Sentry.captureException).toHaveBeenCalledWith(error);
  });

  it('renders "not found" message when query returns a NOT_FOUND status', async () => {
    createComponent({
      handler: jest.fn().mockResolvedValue(getErrorTrackingQueryResponse({ status: 'NOT_FOUND' })),
    });
    await waitForPromises();

    expect(findAlert().text()).toBe('Sentry issue not found.');
  });

  it('renders "error" message when query returns an ERROR status', async () => {
    createComponent({
      handler: jest.fn().mockResolvedValue(getErrorTrackingQueryResponse({ status: 'ERROR' })),
    });
    await waitForPromises();

    expect(findAlert().text()).toBe('Error tracking service responded with an error.');
  });
});
