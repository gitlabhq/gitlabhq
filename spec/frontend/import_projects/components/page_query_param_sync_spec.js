import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { TEST_HOST } from 'helpers/test_constants';

import PageQueryParamSync from '~/import_projects/components/page_query_param_sync.vue';

describe('PageQueryParamSync', () => {
  let originalPushState;
  let originalAddEventListener;
  let originalRemoveEventListener;

  const pushStateMock = jest.fn();
  const addEventListenerMock = jest.fn();
  const removeEventListenerMock = jest.fn();

  beforeAll(() => {
    window.location.search = '';
    originalPushState = window.pushState;

    window.history.pushState = pushStateMock;

    originalAddEventListener = window.addEventListener;
    window.addEventListener = addEventListenerMock;

    originalRemoveEventListener = window.removeEventListener;
    window.removeEventListener = removeEventListenerMock;
  });

  afterAll(() => {
    window.history.pushState = originalPushState;
    window.addEventListener = originalAddEventListener;
    window.removeEventListener = originalRemoveEventListener;
  });

  let wrapper;
  beforeEach(() => {
    wrapper = shallowMount(PageQueryParamSync, {
      propsData: { page: 3 },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('calls push state with page number when page is updated and differs from 1', async () => {
    wrapper.setProps({ page: 2 });

    await nextTick();

    const { calls } = pushStateMock.mock;
    expect(calls).toHaveLength(1);
    expect(calls[0][2]).toBe(`${TEST_HOST}/?page=2`);
  });

  it('calls push state without page number when page is updated and is 1', async () => {
    wrapper.setProps({ page: 1 });

    await nextTick();

    const { calls } = pushStateMock.mock;
    expect(calls).toHaveLength(1);
    expect(calls[0][2]).toBe(`${TEST_HOST}/`);
  });

  it('subscribes to popstate event on create', () => {
    expect(addEventListenerMock).toHaveBeenCalledWith('popstate', expect.any(Function));
  });

  it('unsubscribes from popstate event when destroyed', () => {
    const [, fn] = addEventListenerMock.mock.calls[0];

    wrapper.destroy();

    expect(removeEventListenerMock).toHaveBeenCalledWith('popstate', fn);
  });

  it('emits popstate event when popstate is triggered', async () => {
    const [, fn] = addEventListenerMock.mock.calls[0];

    delete window.location;
    window.location = new URL(`${TEST_HOST}/?page=5`);
    fn();

    expect(wrapper.emitted().popstate[0]).toStrictEqual([5]);
  });
});
