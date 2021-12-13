import { beautifyPath } from '~/packages_and_registries/shared/utils';
import { LIST_KEY_PROJECT } from '../constants';

export default (state) =>
  state.packages.map((p) => ({ ...p, projectPathName: beautifyPath(p[LIST_KEY_PROJECT]) }));
