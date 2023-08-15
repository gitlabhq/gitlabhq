import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { TEST_HOST } from 'helpers/test_constants';
import terminalModule from '~/ide/stores/modules/terminal';
import { SET_BRANCH_WORKING_REFERENCE } from '~/ide/stores/mutation_types';
import createTerminalPlugin from '~/ide/stores/plugins/terminal';

const TEST_DATASET = {
  webTerminalSvgPath: `${TEST_HOST}/web/terminal/svg`,
  webTerminalHelpPath: `${TEST_HOST}/web/terminal/help`,
  webTerminalConfigHelpPath: `${TEST_HOST}/web/terminal/config/help`,
  webTerminalRunnersHelpPath: `${TEST_HOST}/web/terminal/runners/help`,
};
Vue.use(Vuex);

describe('ide/stores/extend', () => {
  let store;

  beforeEach(() => {
    const el = document.createElement('div');
    Object.assign(el.dataset, TEST_DATASET);

    store = new Vuex.Store({
      mutations: {
        [SET_BRANCH_WORKING_REFERENCE]: () => {},
      },
    });

    jest.spyOn(store, 'registerModule').mockImplementation();
    jest.spyOn(store, 'dispatch').mockImplementation();

    const plugin = createTerminalPlugin(el);

    plugin(store);
  });

  it('registers terminal module', () => {
    expect(store.registerModule).toHaveBeenCalledWith('terminal', terminalModule());
  });

  it('dispatches terminal/setPaths', () => {
    expect(store.dispatch).toHaveBeenCalledWith('terminal/setPaths', {
      webTerminalSvgPath: TEST_DATASET.webTerminalSvgPath,
      webTerminalHelpPath: TEST_DATASET.webTerminalHelpPath,
      webTerminalConfigHelpPath: TEST_DATASET.webTerminalConfigHelpPath,
      webTerminalRunnersHelpPath: TEST_DATASET.webTerminalRunnersHelpPath,
    });
  });

  it(`dispatches terminal/init on ${SET_BRANCH_WORKING_REFERENCE}`, () => {
    store.dispatch.mockReset();

    store.commit(SET_BRANCH_WORKING_REFERENCE);

    expect(store.dispatch).toHaveBeenCalledWith('terminal/init');
  });
});
