import { something } from 'infection-pkg'; // eslint-disable-line import/no-unresolved
import { helper } from './utils';

export function initApp() {
  helper();
  something();
}
