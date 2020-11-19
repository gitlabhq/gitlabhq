import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlButton, GlModal } from '@gitlab/ui';
import DeployFreezeModal from '~/deploy_freeze/components/deploy_freeze_modal.vue';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown.vue';
import createStore from '~/deploy_freeze/store';
import { freezePeriodsFixture, timezoneDataFixture } from '../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Deploy freeze modal', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore({
      projectId: '8',
      timezoneData: timezoneDataFixture,
    });
    wrapper = shallowMount(DeployFreezeModal, {
      attachToDocument: true,
      stubs: {
        GlModal,
      },
      localVue,
      store,
    });
  });

  const findModal = () => wrapper.find(GlModal);
  const addDeployFreezeButton = () =>
    findModal()
      .findAll(GlButton)
      .at(1);

  const setInput = (freezeStartCron, freezeEndCron, selectedTimezone) => {
    store.state.freezeStartCron = freezeStartCron;
    store.state.freezeEndCron = freezeEndCron;
    store.state.selectedTimezone = selectedTimezone;

    wrapper.find('#deploy-freeze-start').trigger('input');
    wrapper.find('#deploy-freeze-end').trigger('input');
    wrapper.find(TimezoneDropdown).trigger('input');
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Basic interactions', () => {
    it('button is disabled when freeze period is invalid', () => {
      expect(addDeployFreezeButton().attributes('disabled')).toBeTruthy();
    });
  });

  describe('Adding a new deploy freeze', () => {
    beforeEach(() => {
      const { freeze_start, freeze_end, cron_timezone } = freezePeriodsFixture[0];
      setInput(freeze_start, freeze_end, cron_timezone);
    });

    it('button is enabled when valid freeze period settings are present', () => {
      expect(addDeployFreezeButton().attributes('disabled')).toBeUndefined();
    });
  });

  describe('Validations', () => {
    describe('when the cron state is invalid', () => {
      beforeEach(() => {
        setInput('invalid cron', 'invalid cron', 'invalid timezone');
      });

      it('disables the add deploy freeze button', () => {
        expect(addDeployFreezeButton().attributes('disabled')).toBeTruthy();
      });
    });

    describe('when the cron state is valid', () => {
      beforeEach(() => {
        const { freeze_start, freeze_end, cron_timezone } = freezePeriodsFixture[0];
        setInput(freeze_start, freeze_end, cron_timezone);
      });

      it('does not disable the submit button', () => {
        expect(addDeployFreezeButton().attributes('disabled')).toBeFalsy();
      });
    });
  });
});
