import axios from '~/lib/utils/axios_utils';
import { reportToSentry } from '~/ci/utils';

export const reportPerformance = (path, stats) => {
  // FIXME: https://gitlab.com/gitlab-org/gitlab/-/issues/330245
  if (!path) {
    return;
  }

  axios.post(path, stats).catch((err) => {
    reportToSentry('links_inner_perf', `error: ${err}`);
  });
};
