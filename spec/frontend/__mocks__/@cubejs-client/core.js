let mockLoad = jest.fn();
let mockMetadata = jest.fn();

export const CubeApi = jest.fn().mockImplementation(() => ({
  load: mockLoad,
  meta: mockMetadata,
}));

export const HttpTransport = jest.fn();

export const GRANULARITIES = [
  {
    name: 'seconds',
    title: 'Seconds',
  },
];

// eslint-disable-next-line no-underscore-dangle
export const __setMockLoad = (x) => {
  mockLoad = x;
};

// eslint-disable-next-line no-underscore-dangle
export const __setMockMetadata = (x) => {
  mockMetadata = x;
};
