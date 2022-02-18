import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { listen } from 'codesandbox-api';
import { nextTick } from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import ClientsideNavigator from '~/ide/components/preview/navigator.vue';

jest.mock('codesandbox-api', () => ({
  listen: jest.fn().mockReturnValue(jest.fn()),
}));

describe('IDE clientside preview navigator', () => {
  let wrapper;
  let manager;
  let listenHandler;

  const findBackButton = () => wrapper.findAll('button').at(0);
  const findForwardButton = () => wrapper.findAll('button').at(1);
  const findRefreshButton = () => wrapper.findAll('button').at(2);

  beforeEach(() => {
    listen.mockClear();
    manager = { bundlerURL: TEST_HOST, iframe: { src: '' } };

    wrapper = shallowMount(ClientsideNavigator, { propsData: { manager } });
    [[listenHandler]] = listen.mock.calls;
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders readonly URL bar', async () => {
    listenHandler({ type: 'urlchange', url: manager.bundlerURL });
    await nextTick();
    expect(wrapper.find('input[readonly]').element.value).toBe('/');
  });

  it('renders loading icon by default', () => {
    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('removes loading icon when done event is fired', async () => {
    listenHandler({ type: 'done' });
    await nextTick();
    expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
  });

  it('does not count visiting same url multiple times', async () => {
    listenHandler({ type: 'done' });
    listenHandler({ type: 'done', url: `${TEST_HOST}/url1` });
    listenHandler({ type: 'done', url: `${TEST_HOST}/url1` });
    await nextTick();
    expect(findBackButton().attributes('disabled')).toBe('disabled');
  });

  it('unsubscribes from listen on destroy', () => {
    const unsubscribeFn = listen();

    wrapper.destroy();
    expect(unsubscribeFn).toHaveBeenCalled();
  });

  describe('back button', () => {
    beforeEach(async () => {
      listenHandler({ type: 'done' });
      listenHandler({ type: 'urlchange', url: TEST_HOST });
      await nextTick();
    });

    it('is disabled by default', () => {
      expect(findBackButton().attributes('disabled')).toBe('disabled');
    });

    it('is enabled when there is previous entry', async () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });
      await nextTick();
      findBackButton().trigger('click');
      expect(findBackButton().attributes('disabled')).toBeFalsy();
    });

    it('is disabled when there is no previous entry', async () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });

      await nextTick();
      findBackButton().trigger('click');

      await nextTick();
      expect(findBackButton().attributes('disabled')).toBe('disabled');
    });

    it('updates manager iframe src', async () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url2` });
      await nextTick();
      findBackButton().trigger('click');

      expect(manager.iframe.src).toBe(`${TEST_HOST}/url1`);
    });
  });

  describe('forward button', () => {
    beforeEach(async () => {
      listenHandler({ type: 'done' });
      listenHandler({ type: 'urlchange', url: TEST_HOST });
      await nextTick();
    });

    it('is disabled by default', () => {
      expect(findForwardButton().attributes('disabled')).toBe('disabled');
    });

    it('is enabled when there is next entry', async () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });

      await nextTick();
      findBackButton().trigger('click');

      await nextTick();
      expect(findForwardButton().attributes('disabled')).toBeFalsy();
    });

    it('is disabled when there is no next entry', async () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });

      await nextTick();
      findBackButton().trigger('click');

      await nextTick();
      findForwardButton().trigger('click');

      await nextTick();
      expect(findForwardButton().attributes('disabled')).toBe('disabled');
    });

    it('updates manager iframe src', async () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url2` });
      await nextTick();
      findBackButton().trigger('click');

      expect(manager.iframe.src).toBe(`${TEST_HOST}/url1`);
    });
  });

  describe('refresh button', () => {
    const url = `${TEST_HOST}/some_url`;
    beforeEach(async () => {
      listenHandler({ type: 'done' });
      listenHandler({ type: 'urlchange', url });
      await nextTick();
    });

    it('calls refresh with current path', () => {
      manager.iframe.src = 'something-other';
      findRefreshButton().trigger('click');

      expect(manager.iframe.src).toBe(url);
    });
  });
});
