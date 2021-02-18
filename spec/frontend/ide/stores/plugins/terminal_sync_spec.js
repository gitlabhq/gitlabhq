import eventHub from '~/ide/eventhub';
import { createStore } from '~/ide/stores';
import { RUNNING, STOPPING } from '~/ide/stores/modules/terminal/constants';
import { SET_SESSION_STATUS } from '~/ide/stores/modules/terminal/mutation_types';
import createTerminalPlugin from '~/ide/stores/plugins/terminal';
import createTerminalSyncPlugin from '~/ide/stores/plugins/terminal_sync';
import { createTriggerUpdatePayload } from '../../helpers';

jest.mock('~/ide/lib/mirror');

const ACTION_START = 'terminalSync/start';
const ACTION_STOP = 'terminalSync/stop';
const ACTION_UPLOAD = 'terminalSync/upload';
const FILES_CHANGE_EVENT = 'ide.files.change';

describe('IDE stores/plugins/mirror', () => {
  let store;

  beforeEach(() => {
    const root = document.createElement('div');

    store = createStore();
    createTerminalPlugin(root)(store);

    store.dispatch = jest.fn(() => Promise.resolve());

    createTerminalSyncPlugin(root)(store);
  });

  it('does nothing on ide.files.change event', () => {
    eventHub.$emit(FILES_CHANGE_EVENT);

    expect(store.dispatch).not.toHaveBeenCalled();
  });

  describe('when session starts running', () => {
    beforeEach(() => {
      store.commit(`terminal/${SET_SESSION_STATUS}`, RUNNING);
    });

    it('starts', () => {
      expect(store.dispatch).toHaveBeenCalledWith(ACTION_START);
    });

    it('uploads when ide.files.change is emitted', () => {
      expect(store.dispatch).not.toHaveBeenCalledWith(ACTION_UPLOAD);

      eventHub.$emit(FILES_CHANGE_EVENT);

      jest.runAllTimers();

      expect(store.dispatch).toHaveBeenCalledWith(ACTION_UPLOAD);
    });

    it('does nothing when ide.files.change is emitted with "update"', () => {
      eventHub.$emit(FILES_CHANGE_EVENT, createTriggerUpdatePayload('foo'));

      jest.runAllTimers();

      expect(store.dispatch).not.toHaveBeenCalledWith(ACTION_UPLOAD);
    });

    describe('when session stops', () => {
      beforeEach(() => {
        store.commit(`terminal/${SET_SESSION_STATUS}`, STOPPING);
      });

      it('stops', () => {
        expect(store.dispatch).toHaveBeenCalledWith(ACTION_STOP);
      });

      it('does not upload anymore', () => {
        eventHub.$emit(FILES_CHANGE_EVENT);

        jest.runAllTimers();

        expect(store.dispatch).not.toHaveBeenCalledWith(ACTION_UPLOAD);
      });
    });
  });
});
