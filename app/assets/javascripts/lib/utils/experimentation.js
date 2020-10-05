export function isExperimentEnabled(experimentKey) {
  return Boolean(window.gon?.experiments?.[experimentKey]);
}
