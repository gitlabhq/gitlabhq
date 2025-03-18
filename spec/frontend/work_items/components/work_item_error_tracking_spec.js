import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import WorkItemErrorTracking from '~/work_items/components/work_item_error_tracking.vue';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('WorkItemErrorTracking component', () => {
  let axiosMock;
  let wrapper;

  const successResponse = {
    error: {
      stack_trace_entries: [{ id: 1 }, { id: 2 }],
    },
  };

  const findStacktrace = () => wrapper.findComponent(Stacktrace);

  const createComponent = () => {
    wrapper = shallowMount(WorkItemErrorTracking, {
      propsData: {
        fullPath: 'group/project',
        identifier: '12345',
      },
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('renders h2 heading', () => {
    createComponent();

    expect(wrapper.find('h2').text()).toBe('Stack trace');
  });

  it('makes call to stack trace endpoint', async () => {
    createComponent();
    await waitForPromises();

    expect(axiosMock.history.get[0].url).toBe(
      '/group/project/-/error_tracking/12345/stack_trace.json',
    );
  });

  it('renders Stacktrace component when we get data', async () => {
    axiosMock.onGet().reply(HTTP_STATUS_OK, successResponse);
    createComponent();
    await waitForPromises();

    expect(findStacktrace().props('entries')).toEqual(
      successResponse.error.stack_trace_entries.toReversed(),
    );
  });

  it('renders alert when we fail to get data', async () => {
    axiosMock.onGet().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    createComponent();
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to load stacktrace.' });
  });
});
