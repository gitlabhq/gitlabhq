import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlAlert } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import WebIdeAlert from '~/blob/suggest_web_ide_ci/components/web_ide_alert.vue';

const dismissEndpoint = '/-/user_callouts';
const featureId = 'web_ide_alert_dismissed';
const editPath = 'edit/master/-/.gitlab-ci.yml';

describe('WebIdeAlert', () => {
  let wrapper;
  let mock;

  const findButton = () => wrapper.find(GlButton);
  const findAlert = () => wrapper.find(GlAlert);
  const dismissAlert = alertWrapper => alertWrapper.vm.$emit('dismiss');
  const getPostPayload = () => JSON.parse(mock.history.post[0].data);

  const createComponent = () => {
    wrapper = shallowMount(WebIdeAlert, {
      propsData: {
        dismissEndpoint,
        featureId,
        editPath,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onPost(dismissEndpoint).reply(200);

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  describe('with defaults', () => {
    it('displays alert correctly', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('web ide button link has correct path', () => {
      expect(findButton().attributes('href')).toBe(editPath);
    });

    it('dismisses alert correctly', async () => {
      const alertWrapper = findAlert();

      dismissAlert(alertWrapper);

      await waitForPromises();

      expect(alertWrapper.exists()).toBe(false);
      expect(mock.history.post).toHaveLength(1);
      expect(getPostPayload()).toEqual({ feature_name: featureId });
    });
  });
});
