import { LIST_KEY_PROJECT } from '../constants';
import { beautifyPath } from '../../shared/utils';

export default state =>
  state.packages.map(p => ({ ...p, projectPathName: beautifyPath(p[LIST_KEY_PROJECT]) }));
