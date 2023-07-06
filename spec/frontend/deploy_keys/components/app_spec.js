import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import data from 'test_fixtures/deploy_keys/keys.json';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import deployKeysApp from '~/deploy_keys/components/app.vue';
import ConfirmModal from '~/deploy_keys/components/confirm_modal.vue';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import eventHub from '~/deploy_keys/eventhub';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const TEST_ENDPOINT = `${TEST_HOST}/dummy/`;

describe('Deploy keys app component', () => {
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
    mock.onGet(TEST_ENDPOINT).reply(HTTP_STATUS_OK, data);
  });

  afterEach(() => {
    mock.restore();
  });

  const findLoadingIcon = () => wrapper.find('.gl-spinner');
  const findKeyPanels = () => wrapper.findAll('.deploy-keys .gl-tabs-nav li');
  const findModal = () => wrapper.findComponent(ConfirmModal);
  const findNavigationTabs = () => wrapper.findComponent(NavigationTabs);

  it('renders loading icon while waiting for request', async () => {
    mock.onGet(TEST_ENDPOINT).reply(() => new Promise());

    mountComponent();

    await nextTick();
    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders keys panels', async () => {
    await mountComponent();
    expect(findKeyPanels().length).toBe(3);
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
    mock.onGet(TEST_ENDPOINT).reply(HTTP_STATUS_OK, []);

    return mountComponent().then(() => {
      expect(findKeyPanels().length).toBe(0);
    });
  });

  it('hasKeys returns true when there are keys', async () => {
    await mountComponent();

    expect(findNavigationTabs().exists()).toBe(true);
    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('enabling and disabling keys', () => {
    const key = data.public_keys[0];
    let getMethodMock;
    let putMethodMock;

    const removeKey = async (keyEvent) => {
      eventHub.$emit(keyEvent, key, () => {});

      await nextTick();
      expect(findModal().props('visible')).toBe(true);
      findModal().vm.$emit('remove');
    };

    beforeEach(() => {
      getMethodMock = jest.spyOn(axios, 'get');
      putMethodMock = jest.spyOn(axios, 'put');
    });

    afterEach(() => {
      getMethodMock.mockClear();
      putMethodMock.mockClear();
    });

    it('re-fetches deploy keys when enabling a key', async () => {
      await mountComponent();

      eventHub.$emit('enable.key', key);

      expect(putMethodMock).toHaveBeenCalledWith(`${TEST_ENDPOINT}/${key.id}/enable`);
      expect(getMethodMock).toHaveBeenCalled();
    });

    it('re-fetches deploy keys when disabling a key', async () => {
      await mountComponent();

      await removeKey('disable.key');

      expect(putMethodMock).toHaveBeenCalledWith(`${TEST_ENDPOINT}/${key.id}/disable`);
      expect(getMethodMock).toHaveBeenCalled();
    });

    it('calls disableKey when removing a key', async () => {
      await mountComponent();

      await removeKey('remove.key');

      expect(putMethodMock).toHaveBeenCalledWith(`${TEST_ENDPOINT}/${key.id}/disable`);
      expect(getMethodMock).toHaveBeenCalled();
    });
  });
});
