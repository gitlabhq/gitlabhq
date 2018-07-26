import ServiceDeskStore from 'ee/projects/settings_service_desk/stores/service_desk_store';

describe('ServiceDeskStore', () => {
  let store;

  beforeEach(() => {
    store = new ServiceDeskStore();
  });

  describe('setIncomingEmail', () => {
    it('defaults to an empty string', () => {
      expect(store.state.incomingEmail).toEqual('');
    });

    it('set true', () => {
      const email = 'foo@bar.com';
      store.setIncomingEmail(email);

      expect(store.state.incomingEmail).toEqual(email);
    });
  });

  describe('resetIncomingEmail', () => {
    it('resets to empty string', () => {
      store.setIncomingEmail('foo');
      store.resetIncomingEmail();

      expect(store.state.incomingEmail).toEqual('');
    });
  });
});
