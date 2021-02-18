import { debounce } from 'lodash';
import { commitActionTypes } from '~/ide/constants';
import eventHub from '~/ide/eventhub';
import { isEndingStatus, isRunningStatus } from '../modules/terminal/utils';
import terminalSyncModule from '../modules/terminal_sync';

const UPLOAD_DEBOUNCE = 200;

/**
 * Registers and controls the terminalSync vuex module based on IDE events.
 *
 * - Watches the terminal session status state to control start/stop.
 * - Listens for file change event to control upload.
 */
export default function createMirrorPlugin() {
  return (store) => {
    store.registerModule('terminalSync', terminalSyncModule());

    const upload = debounce(() => {
      store.dispatch(`terminalSync/upload`);
    }, UPLOAD_DEBOUNCE);

    const onFilesChange = (payload) => {
      // Do nothing on a file update since we only want to trigger manually on "save".
      if (payload?.type === commitActionTypes.update) {
        return;
      }

      upload();
    };

    const stop = () => {
      store.dispatch(`terminalSync/stop`);
      eventHub.$off('ide.files.change', onFilesChange);
    };

    const start = () => {
      store
        .dispatch(`terminalSync/start`)
        .then(() => {
          eventHub.$on('ide.files.change', onFilesChange);
        })
        .catch(() => {
          // error is handled in store
        });
    };

    store.watch(
      (x) => x.terminal && x.terminal.session && x.terminal.session.status,
      (val) => {
        if (isRunningStatus(val)) {
          start();
        } else if (isEndingStatus(val)) {
          stop();
        }
      },
    );
  };
}
