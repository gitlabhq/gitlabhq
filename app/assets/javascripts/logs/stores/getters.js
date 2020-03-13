import { formatDate } from '../utils';

const mapTrace = ({ timestamp = null, message = '' }) =>
  [timestamp ? formatDate(timestamp) : '', message].join(' | ');

export const trace = state => state.logs.lines.map(mapTrace).join('\n');

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
