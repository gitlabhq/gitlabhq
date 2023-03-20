import { merge } from 'lodash';

// This helper is for specs that use `gitlab/experimentation` module
export function withGonExperiment(experimentKey, value = true) {
  beforeEach(() => {
    window.gon = merge({}, window.gon || {}, { experiments: { [experimentKey]: value } });
  });
}

// The following helper is for specs that use `gitlab-experiment` utilities,
// which have a different schema that gets pushed to the frontend compared to
// the `Experimentation` Module.
//
// Usage: stubExperiments({ experiment_feature_flag_name: 'variant_name', ... })
export function stubExperiments(experiments = {}) {
  // Deprecated
  window.gon = window.gon || {};
  window.gon.experiment = window.gon.experiment || {};
  // Preferred
  window.gl = window.gl || {};
  window.gl.experiments = window.gl.experiments || {};

  Object.entries(experiments).forEach(([name, variant]) => {
    const experimentData = { experiment: name, variant };

    // Deprecated
    window.gon.experiment[name] = experimentData;
    // Preferred
    window.gl.experiments[name] = experimentData;
  });
}
