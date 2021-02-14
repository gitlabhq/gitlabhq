import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { listen } from 'codesandbox-api';
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

  it('renders readonly URL bar', () => {
    listenHandler({ type: 'urlchange', url: manager.bundlerURL });
    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find('input[readonly]').element.value).toBe('/');
    });
  });

  it('renders loading icon by default', () => {
    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('removes loading icon when done event is fired', () => {
    listenHandler({ type: 'done' });
    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });
  });

  it('does not count visiting same url multiple times', () => {
    listenHandler({ type: 'done' });
    listenHandler({ type: 'done', url: `${TEST_HOST}/url1` });
    listenHandler({ type: 'done', url: `${TEST_HOST}/url1` });
    return wrapper.vm.$nextTick().then(() => {
      expect(findBackButton().attributes('disabled')).toBe('disabled');
    });
  });

  it('unsubscribes from listen on destroy', () => {
    const unsubscribeFn = listen();

    wrapper.destroy();
    expect(unsubscribeFn).toHaveBeenCalled();
  });

  describe('back button', () => {
    beforeEach(() => {
      listenHandler({ type: 'done' });
      listenHandler({ type: 'urlchange', url: TEST_HOST });
      return wrapper.vm.$nextTick();
    });

    it('is disabled by default', () => {
      expect(findBackButton().attributes('disabled')).toBe('disabled');
    });

    it('is enabled when there is previous entry', () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });
      return wrapper.vm.$nextTick().then(() => {
        findBackButton().trigger('click');
        expect(findBackButton().attributes('disabled')).toBeFalsy();
      });
    });

    it('is disabled when there is no previous entry', () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });
      return wrapper.vm
        .$nextTick()
        .then(() => {
          findBackButton().trigger('click');

          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(findBackButton().attributes('disabled')).toBe('disabled');
        });
    });

    it('updates manager iframe src', () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url2` });
      return wrapper.vm.$nextTick().then(() => {
        findBackButton().trigger('click');

        expect(manager.iframe.src).toBe(`${TEST_HOST}/url1`);
      });
    });
  });

  describe('forward button', () => {
    beforeEach(() => {
      listenHandler({ type: 'done' });
      listenHandler({ type: 'urlchange', url: TEST_HOST });
      return wrapper.vm.$nextTick();
    });

    it('is disabled by default', () => {
      expect(findForwardButton().attributes('disabled')).toBe('disabled');
    });

    it('is enabled when there is next entry', () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });
      return wrapper.vm
        .$nextTick()
        .then(() => {
          findBackButton().trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(findForwardButton().attributes('disabled')).toBeFalsy();
        });
    });

    it('is disabled when there is no next entry', () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });
      return wrapper.vm
        .$nextTick()
        .then(() => {
          findBackButton().trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          findForwardButton().trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(findForwardButton().attributes('disabled')).toBe('disabled');
        });
    });

    it('updates manager iframe src', () => {
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url1` });
      listenHandler({ type: 'urlchange', url: `${TEST_HOST}/url2` });
      return wrapper.vm.$nextTick().then(() => {
        findBackButton().trigger('click');

        expect(manager.iframe.src).toBe(`${TEST_HOST}/url1`);
      });
    });
  });

  describe('refresh button', () => {
    const url = `${TEST_HOST}/some_url`;
    beforeEach(() => {
      listenHandler({ type: 'done' });
      listenHandler({ type: 'urlchange', url });
      return wrapper.vm.$nextTick();
    });

    it('calls refresh with current path', () => {
      manager.iframe.src = 'something-other';
      findRefreshButton().trigger('click');

      expect(manager.iframe.src).toBe(url);
    });
  });
});
