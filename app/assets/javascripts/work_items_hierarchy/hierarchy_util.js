import { LICENSE_PLAN } from './constants';

export function inferLicensePlan({ hasSubEpics, hasEpics }) {
  if (hasSubEpics) {
    return LICENSE_PLAN.ULTIMATE;
  }
  if (hasEpics) {
    return LICENSE_PLAN.PREMIUM;
  }
  return LICENSE_PLAN.FREE;
}
