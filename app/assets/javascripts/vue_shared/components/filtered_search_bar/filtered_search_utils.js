export const stripQuotes = value => {
  return value.includes(' ') ? value.slice(1, -1) : value;
};
