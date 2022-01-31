import { inferLicensePlan } from '~/work_items_hierarchy/hierarchy_util';
import { LICENSE_PLAN } from '~/work_items_hierarchy/constants';

describe('inferLicensePlan', () => {
  it.each`
    epics    | subEpics | licensePlan
    ${true}  | ${true}  | ${LICENSE_PLAN.ULTIMATE}
    ${true}  | ${false} | ${LICENSE_PLAN.PREMIUM}
    ${false} | ${false} | ${LICENSE_PLAN.FREE}
  `(
    'returns $licensePlan when epic is $epics and sub-epic is $subEpics',
    ({ epics, subEpics, licensePlan }) => {
      expect(inferLicensePlan({ hasEpics: epics, hasSubEpics: subEpics })).toBe(licensePlan);
    },
  );
});
