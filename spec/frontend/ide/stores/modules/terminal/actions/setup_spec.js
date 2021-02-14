import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/ide/stores/modules/terminal/actions/setup';
import * as mutationTypes from '~/ide/stores/modules/terminal/mutation_types';

describe('IDE store terminal setup actions', () => {
  describe('init', () => {
    it('dispatches checks', () => {
      return testAction(
        actions.init,
        null,
        {},
        [],
        [{ type: 'fetchConfigCheck' }, { type: 'fetchRunnersCheck' }],
      );
    });
  });

  describe('hideSplash', () => {
    it('commits HIDE_SPLASH', () => {
      return testAction(actions.hideSplash, null, {}, [{ type: mutationTypes.HIDE_SPLASH }], []);
    });
  });

  describe('setPaths', () => {
    it('commits SET_PATHS', () => {
      const paths = {
        foo: 'bar',
        lorem: 'ipsum',
      };

      return testAction(
        actions.setPaths,
        paths,
        {},
        [{ type: mutationTypes.SET_PATHS, payload: paths }],
        [],
      );
    });
  });
});
