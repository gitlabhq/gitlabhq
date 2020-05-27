/* eslint-disable class-methods-use-this */
class MutationObserverStub {
  disconnect() {}
  observe() {}
}

global.MutationObserver = MutationObserverStub;
