class ServiceDeskStore {
  constructor(initialState = {}) {
    this.state = Object.assign({
      isEnabled: false,
      incomingEmail: '',
      fetchError: null,
    }, initialState);
  }

  setIsActivated(value) {
    this.state.isEnabled = value;
  }

  setIncomingEmail(value) {
    this.state.incomingEmail = value;
  }

  setFetchError(value) {
    this.state.fetchError = new Error(value);
  }
}

export default ServiceDeskStore;
