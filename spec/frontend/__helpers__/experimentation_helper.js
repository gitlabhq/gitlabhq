// The following helper is for specs that use `gitlab-experiment` utilities,
// which have a different schema that gets pushed to the frontend compared to
// the `Experimentation` Module.
//
// Usage: stubExperiments({ experiment_feature_flag_name: 'variant_name', ... })
export function stubExperiments(experiments = {}) {
  window.gl = window.gl || {};
  window.gl.experiments = window.gl.experiments || {};

  Object.entries(experiments).forEach(([name, variant]) => {
    const experimentData = { experiment: name, variant };

    window.gl.experiments[name] = experimentData;
  });
}
