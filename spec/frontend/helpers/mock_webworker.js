export default () => {
  const mockWorker = {
    addEventListener: jest.fn(),
    postMessage: jest.fn(),
    terminate: jest.fn(),

    mockClear() {
      this.addEventListener.mockClear();
      this.postMessage.mockClear();
      this.terminate.mockClear();
    },
  };
  return mockWorker;
};
