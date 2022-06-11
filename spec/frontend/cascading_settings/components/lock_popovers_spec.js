import { GlPopover } from '@gitlab/ui';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import LockPopovers from '~/namespaces/cascading_settings/components/lock_popovers.vue';

describe('LockPopovers', () => {
  const mockNamespace = {
    full_name: 'GitLab Org / GitLab',
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

    if (lockedByApplicationSetting) {
      popoverMountEl.setAttribute('data-popover-data', JSON.stringify(popoverData));
    } else if (lockedByAncestor) {
      popoverMountEl.setAttribute(
        'data-popover-data',
        JSON.stringify({ ...popoverData, ancestor_namespace: mockNamespace }),
      );
    }

    document.body.appendChild(popoverMountEl);

    return popoverMountEl;
  };

  let wrapper;
  const createWrapper = () => {
    wrapper = mountExtended(LockPopovers);
  };

  const findPopover = () => extendedWrapper(wrapper.find(GlPopover));
  const findByTextInPopover = (text, options) =>
    findPopover().findByText((_, element) => element.textContent === text, options);

  const expectPopoverMessageExists = (message) => {
    expect(findByTextInPopover(message).exists()).toBe(true);
  };
  const expectCorrectPopoverTarget = (popoverMountEl, popover = findPopover()) => {
    expect(popover.props('target')).toEqual(popoverMountEl);
  };

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('when setting is locked by an application setting', () => {
    let popoverMountEl;

    beforeEach(() => {
      popoverMountEl = createPopoverMountEl({ lockedByApplicationSetting: true });
      createWrapper();
    });

    it('displays correct popover message', () => {
      expectPopoverMessageExists('This setting has been enforced by an instance admin.');
    });

    it('sets `target` prop correctly', () => {
      expectCorrectPopoverTarget(popoverMountEl);
    });
  });

  describe('when setting is locked by an ancestor namespace', () => {
    let popoverMountEl;

    beforeEach(() => {
      popoverMountEl = createPopoverMountEl({ lockedByAncestor: true });
      createWrapper();
    });

    it('displays correct popover message', () => {
      expectPopoverMessageExists(
        `This setting has been enforced by an owner of ${mockNamespace.full_name}.`,
      );
    });

    it('displays link to ancestor namespace', () => {
      expect(
        findByTextInPopover(mockNamespace.full_name, {
          selector: `a[href="${mockNamespace.path}"]`,
        }).exists(),
      ).toBe(true);
    });

    it('sets `target` prop correctly', () => {
      expectCorrectPopoverTarget(popoverMountEl);
    });
  });

  describe('when setting is locked by an application setting and an ancestor namespace', () => {
    let popoverMountEl;

    beforeEach(() => {
      popoverMountEl = createPopoverMountEl({
        lockedByAncestor: true,
        lockedByApplicationSetting: true,
      });
      createWrapper();
    });

    it('application setting takes precedence and correct message is shown', () => {
      expectPopoverMessageExists('This setting has been enforced by an instance admin.');
    });

    it('sets `target` prop correctly', () => {
      expectCorrectPopoverTarget(popoverMountEl);
    });
  });

  describe('when setting is not locked', () => {
    beforeEach(() => {
      createPopoverMountEl({
        lockedByAncestor: false,
        lockedByApplicationSetting: false,
      });
      createWrapper();
    });

    it('does not render popover', () => {
      expect(findPopover().exists()).toBe(false);
    });
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
      const popovers = wrapper.findAll(GlPopover).wrappers;

      expectCorrectPopoverTarget(popoverMountEl1, popovers[0]);
      expectCorrectPopoverTarget(popoverMountEl2, popovers[1]);
    });
  });
});
