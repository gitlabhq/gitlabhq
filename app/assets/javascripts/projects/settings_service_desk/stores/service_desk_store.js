class ServiceDeskStore {
  constructor(initialState = {}) {
    this.state = Object.assign({
      isActivated: false,
      incomingEmail: '',
      fetchError: null,
    }, initialState);
  }

  setIsActivated(value) {
    this.state.isActivated = value;
  }

  setIncomingEmail(value) {
    this.state.incomingEmail = value;
  }

  setFetchError(value) {
    this.state.fetchError = value;
  }
}

export default ServiceDeskStore;
