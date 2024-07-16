import { GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import HamlLockPopover from '~/namespaces/cascading_settings/components/haml_lock_popovers.vue';
import LockPopover from '~/namespaces/cascading_settings/components/lock_popover.vue';

describe('HamlLockPopover', () => {
  const mockNamespace = {
    fullName: 'GitLab Org / GitLab',
    path: '/gitlab-org/gitlab/-/edit',
  };

  const createPopoverMountEl = ({
    lockedByApplicationSetting = false,
    lockedByAncestor = false,
  }) => {
    const popoverMountEl = document.createElement('div');
    popoverMountEl.classList.add('js-cascading-settings-lock-popover-target');

    const popoverData = {
      locked_by_application_setting: lockedByApplicationSetting,
      locked_by_ancestor: lockedByAncestor,
    };

    popoverMountEl.dataset.popoverData = JSON.stringify(popoverData);
    popoverMountEl.dataset.popoverData = JSON.stringify({
      ...popoverData,
      ancestor_namespace: lockedByAncestor && !lockedByApplicationSetting ? mockNamespace : null,
    });

    document.body.appendChild(popoverMountEl);

    return popoverMountEl;
  };

  let wrapper;

  const createWrapper = () => {
    wrapper = mountExtended(HamlLockPopover);
  };

  const findLockPopovers = () => wrapper.findAllComponents(LockPopover);

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
          domElement = createPopoverMountEl({
            ancestorNamespace,
            lockedByApplicationSetting,
            lockedByAncestor,
          });
          createWrapper();
        });

        it('locked_by_application_setting attribute', () => {
          expect(findLockPopovers().at(0).props().isLockedByAdmin).toBe(lockedByApplicationSetting);
        });

        it('locked_by_ancestor attribute', () => {
          expect(findLockPopovers().at(0).props().isLockedByGroupAncestor).toBe(lockedByAncestor);
        });

        it('ancestor_namespace attribute', () => {
          expect(findLockPopovers().at(0).props().ancestorNamespace).toEqual(ancestorNamespace);
        });

        it('target element', () => {
          expect(findLockPopovers().at(0).props().targetElement).toBe(domElement);
        });
      },
    );
  });

  describe('when there are multiple mount elements', () => {
    let popoverMountEl1;
    let popoverMountEl2;

    beforeEach(() => {
      popoverMountEl1 = createPopoverMountEl({ lockedByApplicationSetting: true });
      popoverMountEl2 = createPopoverMountEl({ lockedByAncestor: true });
      createWrapper();
    });

    it('mounts multiple popovers', () => {
      const popovers = wrapper.findAllComponents(GlPopover).wrappers;

      expect(popovers).toHaveLength(2);
      expect(popovers[0].props('target')).toBe(popoverMountEl1);
      expect(popovers[1].props('target')).toBe(popoverMountEl2);
    });
  });
});
