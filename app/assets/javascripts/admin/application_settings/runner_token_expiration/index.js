import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseInterval } from '~/ci/runner/utils';
import ExpirationIntervals from './components/expiration_intervals.vue';

const initRunnerTokenExpirationIntervals = (selector = '#js-runner-token-expiration-intervals') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const {
    instanceRunnerTokenExpirationInterval,
    groupRunnerTokenExpirationInterval,
    projectRunnerTokenExpirationInterval,
  } = el.dataset;

  return initVueApp({
    el,
    name: 'ExpirationIntervalsRoot',
    component: ExpirationIntervals,
    props: {
      instanceRunnerExpirationInterval: parseInterval(instanceRunnerTokenExpirationInterval),
      groupRunnerExpirationInterval: parseInterval(groupRunnerTokenExpirationInterval),
      projectRunnerExpirationInterval: parseInterval(projectRunnerTokenExpirationInterval),
    },
  });
};

export default initRunnerTokenExpirationIntervals;
