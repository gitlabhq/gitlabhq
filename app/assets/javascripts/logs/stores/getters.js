import dateFormat from 'dateformat';

export const trace = state =>
  state.logs.lines
    .map(item => [dateFormat(item.timestamp, 'UTC:mmm dd HH:MM:ss.l"Z"'), item.message].join(' | '))
    .join('\n');

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
