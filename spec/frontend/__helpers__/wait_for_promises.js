// eslint-disable-next-line no-restricted-syntax
export default () => new Promise(jest.requireActual('timers').setImmediate);
