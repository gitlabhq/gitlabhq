// eslint-disable-next-line import/prefer-default-export
export const stripQuotes = value => {
  return value.includes(' ') ? value.slice(1, -1) : value;
};
