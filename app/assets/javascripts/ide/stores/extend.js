import terminal from './plugins/terminal';
import terminalSync from './plugins/terminal_sync';

const plugins = () => [
  terminal,
  ...(gon.features && gon.features.buildServiceProxy ? [terminalSync] : []),
];

export default (store, el) => {
  // plugins is actually an array of plugin factories, so we have to create first then call
  plugins().forEach((plugin) => plugin(el)(store));

  return store;
};
