import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import DeployFreezeTable from '~/deploy_freeze/components/deploy_freeze_table.vue';
import createStore from '~/deploy_freeze/store';
import { mockFreezePeriods, mockTimezoneData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Deploy freeze table', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    store = createStore({
      projectId: '8',
      timezoneData: mockTimezoneData,
    });
    jest.spyOn(store, 'dispatch').mockImplementation();
    wrapper = mount(DeployFreezeTable, {
      attachToDocument: true,
      localVue,
      store,
    });
  };

  const findEmptyFreezePeriods = () => wrapper.find('[data-testid="empty-freeze-periods"]');
  const findAddDeployFreezeButton = () => wrapper.find('[data-testid="add-deploy-freeze"]');
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
        'No deploy freezes exist for this project. To add one, click Add deploy freeze',
      );
    });

    it('displays data', () => {
      store.state.freezePeriods = mockFreezePeriods;

      return wrapper.vm.$nextTick(() => {
        const tableRows = findDeployFreezeTable().findAll('tbody tr');
        expect(tableRows.length).toBe(mockFreezePeriods.length);
        expect(findEmptyFreezePeriods().exists()).toBe(false);
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
