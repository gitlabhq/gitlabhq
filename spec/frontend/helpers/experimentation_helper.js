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
