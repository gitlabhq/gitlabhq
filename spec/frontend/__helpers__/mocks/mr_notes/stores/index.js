import { Store } from 'vuex-mock-store';
import createDiffState from 'ee_else_ce/diffs/store/modules/diff_state';
import createNotesState from '~/notes/stores/state';

const store = new Store({
  state: {
    diffs: createDiffState(),
    notes: createNotesState(),
  },
  spy: {
    create: (handler) => jest.fn(handler).mockImplementation(() => Promise.resolve()),
  },
});

export default store;
