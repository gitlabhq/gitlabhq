import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import ResetKey from '~/prometheus_alerts/components/reset_key.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('ResetKey', () => {
  let mock;
  let vm;

  const propsData = {
    initialAuthorizationKey: 'abcd1234',
    changeKeyUrl: '/updateKeyUrl',
    notifyUrl: '/root/autodevops-deploy/prometheus/alerts/notify.json',
    learnMoreUrl: '/learnMore',
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    setFixtures('<div class="flash-container"></div><div id="reset-key"></div>');
  });

  afterEach(() => {
    mock.restore();
    vm.destroy();
  });

  describe('authorization key exists', () => {
    beforeEach(() => {
      propsData.initialAuthorizationKey = 'abcd1234';
      vm = shallowMount(ResetKey, {
        propsData,
      });
    });

    it('shows fields and buttons', () => {
      expect(vm.find('#notify-url').attributes('value')).toEqual(propsData.notifyUrl);
      expect(vm.find('#authorization-key').attributes('value')).toEqual(
        propsData.initialAuthorizationKey,
      );

      expect(vm.findAll(ClipboardButton).length).toBe(2);
      expect(vm.find('.js-reset-auth-key').text()).toEqual('Reset key');
    });

    it('reset updates key', () => {
      mock.onPost(propsData.changeKeyUrl).replyOnce(200, { token: 'newToken' });

      vm.find(GlModal).vm.$emit('ok');

      return vm.vm
        .$nextTick()
        .then(waitForPromises)
        .then(() => {
          expect(vm.vm.authorizationKey).toEqual('newToken');
          expect(vm.find('#authorization-key').attributes('value')).toEqual('newToken');
        });
    });

    it('reset key failure shows error', () => {
      mock.onPost(propsData.changeKeyUrl).replyOnce(500);

      vm.find(GlModal).vm.$emit('ok');

      return vm.vm
        .$nextTick()
        .then(waitForPromises)
        .then(() => {
          expect(vm.find('#authorization-key').attributes('value')).toEqual(
            propsData.initialAuthorizationKey,
          );

          expect(document.querySelector('.flash-container').innerText.trim()).toEqual(
            'Failed to reset key. Please try again.',
          );
        });
    });
  });

  describe('authorization key has not been set', () => {
    beforeEach(() => {
      propsData.initialAuthorizationKey = '';
      vm = shallowMount(ResetKey, {
        propsData,
      });
    });

    it('shows Generate Key button', () => {
      expect(vm.find('.js-reset-auth-key').text()).toEqual('Generate key');
      expect(vm.find('#authorization-key').attributes('value')).toEqual('');
    });

    it('Generate key button triggers key change', () => {
      mock.onPost(propsData.changeKeyUrl).replyOnce(200, { token: 'newToken' });

      vm.find('.js-reset-auth-key').vm.$emit('click');

      return waitForPromises().then(() => {
        expect(vm.find('#authorization-key').attributes('value')).toEqual('newToken');
      });
    });
  });
});
