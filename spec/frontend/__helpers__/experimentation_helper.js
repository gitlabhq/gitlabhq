import { merge } from 'lodash';

export function withGonExperiment(experimentKey, value = true) {
  let origGon;

  beforeEach(() => {
    origGon = window.gon;
    window.gon = merge({}, window.gon || {}, { experiments: { [experimentKey]: value } });
  });

  afterEach(() => {
    window.gon = origGon;
  });
}
// This helper is for specs that use `gitlab-experiment` utilities, which have a different schema that gets pushed via Gon compared to `Experimentation Module`
export function assignGitlabExperiment(experimentKey, variant) {
  let origGon;

  beforeEach(() => {
    origGon = window.gon;
    window.gon = { experiment: { [experimentKey]: { variant } } };
  });

  afterEach(() => {
    window.gon = origGon;
  });
}
