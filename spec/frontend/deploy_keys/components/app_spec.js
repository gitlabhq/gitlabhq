import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import eventHub from '~/deploy_keys/eventhub';
import deployKeysApp from '~/deploy_keys/components/app.vue';

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
  const findKeyPanels = () => wrapper.findAll('.deploy-keys .nav-links li');

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
    selector                                       | label                                 | count
    ${'.js-deployKeys-tab-enabled_keys'}           | ${'Enabled deploy keys'}              | ${1}
    ${'.js-deployKeys-tab-available_project_keys'} | ${'Privately accessible deploy keys'} | ${0}
    ${'.js-deployKeys-tab-public_keys'}            | ${'Publicly accessible deploy keys'}  | ${1}
  `('$selector title is $label with keys count equal to $count', ({ selector, label, count }) => {
    return mountComponent().then(() => {
      const element = wrapper.find(selector);
      expect(element.exists()).toBe(true);
      expect(element.text().trim()).toContain(label);

      expect(
        element
          .find('.badge')
          .text()
          .trim(),
      ).toBe(count.toString());
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
        jest.spyOn(window, 'confirm').mockReturnValue(true);
        jest.spyOn(wrapper.vm.service, 'getKeys').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'disableKey').mockImplementation(() => Promise.resolve());

        eventHub.$emit('disable.key', key);

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
        jest.spyOn(window, 'confirm').mockReturnValue(true);
        jest.spyOn(wrapper.vm.service, 'getKeys').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'disableKey').mockImplementation(() => Promise.resolve());

        eventHub.$emit('remove.key', key);

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
