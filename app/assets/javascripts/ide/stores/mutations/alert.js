import {
  DETECT_ENVIRONMENTS_GUIDANCE_ALERT,
  DISMISS_ENVIRONMENTS_GUIDANCE_ALERT,
} from '../mutation_types';

export default {
  [DETECT_ENVIRONMENTS_GUIDANCE_ALERT](state, stages) {
    if (!stages) {
      return;
    }
    const hasEnvironments = stages?.nodes?.some((stage) =>
      stage.groups.nodes.some((group) => group.jobs.nodes.some((job) => job.environment)),
    );
    const hasParsedCi = Array.isArray(stages.nodes);

    state.environmentsGuidanceAlertDetected = !hasEnvironments && hasParsedCi;
  },
  [DISMISS_ENVIRONMENTS_GUIDANCE_ALERT](state) {
    state.environmentsGuidanceAlertDismissed = true;
  },
};
