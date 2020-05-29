import { debounce } from 'lodash';
import eventHub from '~/ide/eventhub';
import terminalSyncModule from '../modules/terminal_sync';
import { isEndingStatus, isRunningStatus } from '../modules/terminal/utils';

const UPLOAD_DEBOUNCE = 200;

/**
 * Registers and controls the terminalSync vuex module based on IDE events.
 *
 * - Watches the terminal session status state to control start/stop.
 * - Listens for file change event to control upload.
 */
export default function createMirrorPlugin() {
  return store => {
    store.registerModule('terminalSync', terminalSyncModule());

    const upload = debounce(() => {
      store.dispatch(`terminalSync/upload`);
    }, UPLOAD_DEBOUNCE);

    const stop = () => {
      store.dispatch(`terminalSync/stop`);
      eventHub.$off('ide.files.change', upload);
    };

    const start = () => {
      store
        .dispatch(`terminalSync/start`)
        .then(() => {
          eventHub.$on('ide.files.change', upload);
        })
        .catch(() => {
          // error is handled in store
        });
    };

    store.watch(
      x => x.terminal && x.terminal.session && x.terminal.session.status,
      val => {
        if (isRunningStatus(val)) {
          start();
        } else if (isEndingStatus(val)) {
          stop();
        }
      },
    );
  };
}
