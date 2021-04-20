import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import Api from '~/api';
import DeployFreezeModal from '~/deploy_freeze/components/deploy_freeze_modal.vue';
import createStore from '~/deploy_freeze/store';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown.vue';
import { freezePeriodsFixture, timezoneDataFixture } from '../helpers';

jest.mock('~/api');

Vue.use(Vuex);

describe('Deploy freeze modal', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore({
      projectId: '8',
      timezoneData: timezoneDataFixture,
    });
    wrapper = shallowMount(DeployFreezeModal, {
      attachTo: document.body,
      stubs: {
        GlModal,
      },
      store,
    });
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const submitDeployFreezeButton = () => findModal().findAllComponents(GlButton).at(1);

  const setInput = (freezeStartCron, freezeEndCron, selectedTimezone, id = '') => {
    store.state.freezeStartCron = freezeStartCron;
    store.state.freezeEndCron = freezeEndCron;
    store.state.selectedTimezone = selectedTimezone;
    store.state.selectedTimezoneIdentifier = selectedTimezone;
    store.state.selectedId = id;

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
      expect(submitDeployFreezeButton().attributes('disabled')).toBeTruthy();
    });
  });

  describe('Adding a new deploy freeze', () => {
    const { freeze_start, freeze_end, cron_timezone } = freezePeriodsFixture[0];

    beforeEach(() => {
      setInput(freeze_start, freeze_end, cron_timezone);
    });

    it('button is enabled when valid freeze period settings are present', () => {
      expect(submitDeployFreezeButton().attributes('disabled')).toBeUndefined();
    });

    it('should display Add deploy freeze', () => {
      expect(findModal().props('title')).toBe('Add deploy freeze');
      expect(submitDeployFreezeButton().text()).toBe('Add deploy freeze');
    });

    it('should call the add deploy freze API', () => {
      Api.createFreezePeriod.mockResolvedValue();
      findModal().vm.$emit('primary');

      expect(Api.createFreezePeriod).toHaveBeenCalledTimes(1);
      expect(Api.createFreezePeriod).toHaveBeenCalledWith(store.state.projectId, {
        freeze_start,
        freeze_end,
        cron_timezone,
      });
    });
  });

  describe('Validations', () => {
    describe('when the cron state is invalid', () => {
      beforeEach(() => {
        setInput('invalid cron', 'invalid cron', 'invalid timezone');
      });

      it('disables the add deploy freeze button', () => {
        expect(submitDeployFreezeButton().attributes('disabled')).toBeTruthy();
      });
    });

    describe('when the cron state is valid', () => {
      beforeEach(() => {
        const { freeze_start, freeze_end, cron_timezone } = freezePeriodsFixture[0];
        setInput(freeze_start, freeze_end, cron_timezone);
      });

      it('does not disable the submit button', () => {
        expect(submitDeployFreezeButton().attributes('disabled')).toBeFalsy();
      });
    });
  });

  describe('Editing an existing deploy freeze', () => {
    const { freeze_start, freeze_end, cron_timezone, id } = freezePeriodsFixture[0];
    beforeEach(() => {
      setInput(freeze_start, freeze_end, cron_timezone, id);
    });

    it('should display Edit deploy freeze', () => {
      expect(findModal().props('title')).toBe('Edit deploy freeze');
      expect(submitDeployFreezeButton().text()).toBe('Save deploy freeze');
    });

    it('should call the update deploy freze API', () => {
      Api.updateFreezePeriod.mockResolvedValue();
      findModal().vm.$emit('primary');

      expect(Api.updateFreezePeriod).toHaveBeenCalledTimes(1);
      expect(Api.updateFreezePeriod).toHaveBeenCalledWith(store.state.projectId, {
        id,
        freeze_start,
        freeze_end,
        cron_timezone,
      });
    });
  });
});
