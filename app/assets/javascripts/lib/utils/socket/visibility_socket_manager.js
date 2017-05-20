import SocketManager from './socket_manager';

const VisibilitySocketManager = {
  init(socketPath) {
    super.init(socketPath);

    document.addEventListener('visibilitychange', () => this.toggleAllSockets());
  },

  toggleAllSockets() {
    if (document.hidden) {
      super.unsubscribeAll();
    } else {
      super.subscribeAll();
    }
  },
};

Object.setPrototypeOf(VisibilitySocketManager, SocketManager);

// temporary
VisibilitySocketManager.init('/broker');

export default VisibilitySocketManager;
