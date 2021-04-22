import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import deployKeysApp from '~/deploy_keys/components/app.vue';
import ConfirmModal from '~/deploy_keys/components/confirm_modal.vue';
import eventHub from '~/deploy_keys/eventhub';
import axios from '~/lib/utils/axios_utils';

const TEST_ENDPOINT = `${TEST_HOST}/dummy/`;

describe('Deploy keys app component', () => {
  const data = getJSONFixture('deploy_keys/keys.json');
  let wrapper;
  let mock;

  const mountComponent = () => {
    wrapper = mount(deployKeysApp, {
      propsData: {
        endpoint: TEST_ENDPOINT,
        projectId: '8',
      },
    });

    return waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(TEST_ENDPOINT).reply(200, data);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  const findLoadingIcon = () => wrapper.find('.gl-spinner');
  const findKeyPanels = () => wrapper.findAll('.deploy-keys .gl-tabs-nav li');
  const findModal = () => wrapper.findComponent(ConfirmModal);

  it('renders loading icon while waiting for request', () => {
    mock.onGet(TEST_ENDPOINT).reply(() => new Promise());

    mountComponent();

    return wrapper.vm.$nextTick().then(() => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  it('renders keys panels', () => {
    return mountComponent().then(() => {
      expect(findKeyPanels().length).toBe(3);
    });
  });

  it.each`
    selector
    ${'.js-deployKeys-tab-enabled_keys'}
    ${'.js-deployKeys-tab-available_project_keys'}
    ${'.js-deployKeys-tab-public_keys'}
  `('$selector title exists', ({ selector }) => {
    return mountComponent().then(() => {
      const element = wrapper.find(selector);
      expect(element.exists()).toBe(true);
    });
  });

  it('does not render key panels when keys object is empty', () => {
    mock.onGet(TEST_ENDPOINT).reply(200, []);

    return mountComponent().then(() => {
      expect(findKeyPanels().length).toBe(0);
    });
  });

  it('re-fetches deploy keys when enabling a key', () => {
    const key = data.public_keys[0];
    return mountComponent()
      .then(() => {
        jest.spyOn(wrapper.vm.service, 'getKeys').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'enableKey').mockImplementation(() => Promise.resolve());

        eventHub.$emit('enable.key', key);

        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(wrapper.vm.service.enableKey).toHaveBeenCalledWith(key.id);
        expect(wrapper.vm.service.getKeys).toHaveBeenCalled();
      });
  });

  it('re-fetches deploy keys when disabling a key', () => {
    const key = data.public_keys[0];
    return mountComponent()
      .then(() => {
        jest.spyOn(wrapper.vm.service, 'getKeys').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'disableKey').mockImplementation(() => Promise.resolve());

        eventHub.$emit('disable.key', key, () => {});

        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(findModal().props('visible')).toBe(true);
        findModal().vm.$emit('remove');

        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(wrapper.vm.service.disableKey).toHaveBeenCalledWith(key.id);
        expect(wrapper.vm.service.getKeys).toHaveBeenCalled();
      });
  });

  it('calls disableKey when removing a key', () => {
    const key = data.public_keys[0];
    return mountComponent()
      .then(() => {
        jest.spyOn(wrapper.vm.service, 'getKeys').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'disableKey').mockImplementation(() => Promise.resolve());

        eventHub.$emit('remove.key', key, () => {});

        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(findModal().props('visible')).toBe(true);
        findModal().vm.$emit('remove');

        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(wrapper.vm.service.disableKey).toHaveBeenCalledWith(key.id);
        expect(wrapper.vm.service.getKeys).toHaveBeenCalled();
      });
  });

  it('hasKeys returns true when there are keys', () => {
    return mountComponent().then(() => {
      expect(wrapper.vm.hasKeys).toEqual(3);
    });
  });
});
