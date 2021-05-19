import service from '../../services';
import {
  DETECT_ENVIRONMENTS_GUIDANCE_ALERT,
  DISMISS_ENVIRONMENTS_GUIDANCE_ALERT,
} from '../mutation_types';

export const detectGitlabCiFileAlerts = ({ dispatch }, content) =>
  dispatch('detectEnvironmentsGuidance', content);

export const detectEnvironmentsGuidance = ({ commit, state }, content) =>
  service.getCiConfig(state.currentProjectId, content).then((data) => {
    commit(DETECT_ENVIRONMENTS_GUIDANCE_ALERT, data?.stages);
  });

export const dismissEnvironmentsGuidance = ({ commit }) =>
  service.dismissUserCallout('web_ide_ci_environments_guidance').then(() => {
    commit(DISMISS_ENVIRONMENTS_GUIDANCE_ALERT);
  });
