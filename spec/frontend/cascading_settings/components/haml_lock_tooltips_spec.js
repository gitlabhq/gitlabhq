import { GlTooltip } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HamlLockTooltips from '~/namespaces/cascading_settings/components/haml_lock_tooltips.vue';
import LockTooltip from '~/namespaces/cascading_settings/components/lock_tooltip.vue';

describe('HamlLockTooltips', () => {
  const mockNamespace = {
    fullName: 'GitLab Org / GitLab',
    path: '/gitlab-org/gitlab/-/edit',
  };

  const createTooltipMountEl = ({
    lockedByApplicationSetting = false,
    lockedByAncestor = false,
  }) => {
    const tooltipMountEl = document.createElement('div');
    tooltipMountEl.classList.add('js-cascading-settings-lock-tooltip-target');

    const tooltipData = {
      locked_by_application_setting: lockedByApplicationSetting,
      locked_by_ancestor: lockedByAncestor,
    };

    tooltipMountEl.dataset.tooltipData = JSON.stringify(tooltipData);
    tooltipMountEl.dataset.tooltipData = JSON.stringify({
      ...tooltipData,
      ancestor_namespace: lockedByAncestor && !lockedByApplicationSetting ? mockNamespace : null,
    });

    document.body.appendChild(tooltipMountEl);

    return tooltipMountEl;
  };

  let wrapper;

  const createWrapper = () => {
    wrapper = mountExtended(HamlLockTooltips);
  };

  const findLockTooltips = () => wrapper.findAllComponents(LockTooltip);

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('when parsing the DOM', () => {
    let domElement;

    describe.each`
      lockedByApplicationSetting | lockedByAncestor | ancestorNamespace
      ${true}                    | ${true}          | ${null}
      ${false}                   | ${false}         | ${null}
      ${true}                    | ${false}         | ${null}
      ${false}                   | ${true}          | ${mockNamespace}
    `(
      'when locked_by_application_setting is $lockedByApplicationSetting and locked_by_ancestor is $lockedByAncestor and ancestor_namespace is $ancestorNamespace',
      ({ ancestorNamespace, lockedByAncestor, lockedByApplicationSetting }) => {
        beforeEach(() => {
          domElement = createTooltipMountEl({
            ancestorNamespace,
            lockedByApplicationSetting,
            lockedByAncestor,
          });
          createWrapper();
        });

        it('locked_by_application_setting attribute', () => {
          expect(findLockTooltips().at(0).props().isLockedByAdmin).toBe(lockedByApplicationSetting);
        });

        it('locked_by_ancestor attribute', () => {
          expect(findLockTooltips().at(0).props().isLockedByGroupAncestor).toBe(lockedByAncestor);
        });

        it('ancestor_namespace attribute', () => {
          expect(findLockTooltips().at(0).props().ancestorNamespace).toEqual(ancestorNamespace);
        });

        it('target element', () => {
          expect(findLockTooltips().at(0).props().targetElement).toBe(domElement);
        });
      },
    );
  });

  describe('when there are multiple mount elements', () => {
    let tooltipMountEl1;
    let tooltipMountEl2;

    beforeEach(() => {
      tooltipMountEl1 = createTooltipMountEl({ lockedByApplicationSetting: true });
      tooltipMountEl2 = createTooltipMountEl({ lockedByAncestor: true });
      createWrapper();
    });

    it('mounts multiple tooltips', () => {
      const tooltips = wrapper.findAllComponents(GlTooltip).wrappers;

      expect(tooltips).toHaveLength(2);
      expect(tooltips[0].props('target')).toBe(tooltipMountEl1);
      expect(tooltips[1].props('target')).toBe(tooltipMountEl2);
    });
  });
});
