window.DataTransfer = class DataTransfer {
  constructor() {
    this.types = [];
    this.data = {};
  }
  setData(type, value) {
    this.data[type] = value;
  }
  getData(type) {
    if (this.data[type]) {
      return this.data[type];
    }
    if (type === 'text') {
      return this.data['text/plain'];
    }
    return undefined;
  }
};
