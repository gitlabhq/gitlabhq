export const findDefaultOption = options => {
  const item = options.find(o => o.default);
  return item ? item.key : null;
};

export default () => {};
