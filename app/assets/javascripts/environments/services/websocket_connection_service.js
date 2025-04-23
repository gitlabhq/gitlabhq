import { WebSocketWatchManager } from '@gitlab/cluster-client';

let watchManagerInstance = null;

export function resetWatchManager() {
  watchManagerInstance = null;
}

export function getWatchManager(configuration) {
  if (!watchManagerInstance) {
    if (!configuration) {
      throw new Error('WebSocketWatchManager not initialized. Provide configuration first.');
    }
    watchManagerInstance = new WebSocketWatchManager(configuration);
  }

  return watchManagerInstance;
}
