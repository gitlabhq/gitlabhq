export const filterErrorsByTitle = state => errorQuery =>
  state.errors.filter(error => error.title.match(new RegExp(`${errorQuery}`, 'i')));

export default () => {};
