import { RapidDiffsFacade } from '~/rapid_diffs/app';

export const createRapidDiffsApp = (options) => {
  return new RapidDiffsFacade(options);
};
