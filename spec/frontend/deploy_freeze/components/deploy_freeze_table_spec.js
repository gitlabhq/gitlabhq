import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import DeployFreezeTable from '~/deploy_freeze/components/deploy_freeze_table.vue';
import createStore from '~/deploy_freeze/store';
import { RECEIVE_FREEZE_PERIODS_SUCCESS } from '~/deploy_freeze/store/mutation_types';
import { freezePeriodsFixture, timezoneDataFixture } from '../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Deploy freeze table', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    store = createStore({
      projectId: '8',
      timezoneData: timezoneDataFixture,
    });
    jest.spyOn(store, 'dispatch').mockImplementation();
    wrapper = mount(DeployFreezeTable, {
      attachTo: document.body,
      localVue,
      store,
    });
  };

  const findEmptyFreezePeriods = () => wrapper.find('[data-testid="empty-freeze-periods"]');
  const findAddDeployFreezeButton = () => wrapper.find('[data-testid="add-deploy-freeze"]');
  const findEditDeployFreezeButton = () => wrapper.find('[data-testid="edit-deploy-freeze"]');
  const findDeployFreezeTable = () => wrapper.find('[data-testid="deploy-freeze-table"]');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('dispatches fetchFreezePeriods when mounted', () => {
    expect(store.dispatch).toHaveBeenCalledWith('fetchFreezePeriods');
  });

  describe('Renders correct data', () => {
    it('displays empty', () => {
      expect(findEmptyFreezePeriods().exists()).toBe(true);
      expect(findEmptyFreezePeriods().text()).toBe(
        'No deploy freezes exist for this project. To add one, select Add deploy freeze',
      );
    });

    describe('with data', () => {
      beforeEach(async () => {
        store.commit(RECEIVE_FREEZE_PERIODS_SUCCESS, freezePeriodsFixture);
        await wrapper.vm.$nextTick();
      });

      it('displays data', () => {
        const tableRows = findDeployFreezeTable().findAll('tbody tr');
        expect(tableRows.length).toBe(freezePeriodsFixture.length);
        expect(findEmptyFreezePeriods().exists()).toBe(false);
        expect(findEditDeployFreezeButton().exists()).toBe(true);
      });

      it('allows user to edit deploy freeze', async () => {
        findEditDeployFreezeButton().trigger('click');
        await wrapper.vm.$nextTick();

        expect(store.dispatch).toHaveBeenCalledWith(
          'setFreezePeriod',
          store.state.freezePeriods[0],
        );
      });
    });
  });

  describe('Table click actions', () => {
    it('displays add deploy freeze button', () => {
      expect(findAddDeployFreezeButton().exists()).toBe(true);
      expect(findAddDeployFreezeButton().text()).toBe('Add deploy freeze');
    });
  });
});
