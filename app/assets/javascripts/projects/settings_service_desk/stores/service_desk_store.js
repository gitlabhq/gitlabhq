class ServiceDeskStore {
  constructor(initialState = {}) {
    this.state = Object.assign({
      isEnabled: false,
      incomingEmail: '',
      fetchError: null,
      isInstanceAdmin: false,
    }, initialState);
  }

  setIsActivated(value) {
    this.state.isEnabled = value;
  }

  setIncomingEmail(value) {
    this.state.incomingEmail = value;
  }

  setFetchError(value) {
    this.state.fetchError = value;
  }

  setIsInstanceAdmin(value) {
    this.state.isInstanceAdmin = value;
  }
}

export default ServiceDeskStore;
