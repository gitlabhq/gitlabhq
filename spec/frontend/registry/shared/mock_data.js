export const options = [{ key: 'foo', label: 'Foo' }, { key: 'bar', label: 'Bar', default: true }];
export const stringifiedOptions = JSON.stringify(options);
export const stringifiedFormOptions = {
  cadenceOptions: stringifiedOptions,
  keepNOptions: stringifiedOptions,
  olderThanOptions: stringifiedOptions,
};
export const formOptions = {
  cadence: options,
  keepN: options,
  olderThan: options,
};
