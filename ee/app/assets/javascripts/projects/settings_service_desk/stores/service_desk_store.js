class ServiceDeskStore {
  constructor(initialState = {}) {
    this.state = Object.assign({
      incomingEmail: '',
    }, initialState);
  }

  setIncomingEmail(value) {
    this.state.incomingEmail = value;
  }

  resetIncomingEmail() {
    this.state.incomingEmail = '';
  }
}

export default ServiceDeskStore;
