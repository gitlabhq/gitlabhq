import { nextTick } from 'vue';
import Cookies from '~/lib/utils/cookies';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import PinnedSection from '~/super_sidebar/components/pinned_section.vue';
import Draggable from '~/lib/utils/vue3compat/draggable_compat.vue';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import {
  PINNED_NAV_STORAGE_KEY,
  SIDEBAR_PINS_EXPANDED_COOKIE,
  SIDEBAR_COOKIE_EXPIRATION,
  SIDEBAR_PINNED_GROUPS_EXPANDED_STORAGE_KEY,
} from '~/super_sidebar/constants';
import { setCookie } from '~/lib/utils/common_utils';

jest.mock('@floating-ui/dom');
jest.mock('~/lib/utils/common_utils', () => ({
  getCookie: jest.requireActual('~/lib/utils/common_utils').getCookie,
  setCookie: jest.fn(),
}));

describe('PinnedSection component', () => {
  useLocalStorageSpy();

  let wrapper;

  const setGroupStates = (states) =>
    localStorage.setItem(SIDEBAR_PINNED_GROUPS_EXPANDED_STORAGE_KEY, JSON.stringify(states));

  const getGroupStates = () =>
    JSON.parse(localStorage.getItem(SIDEBAR_PINNED_GROUPS_EXPANDED_STORAGE_KEY));

  const findToggle = () => wrapper.find('button');

  const createWrapper = ({ stubs = { Draggable: true }, provide = {}, ...props } = {}) => {
    wrapper = mountExtended(PinnedSection, {
      propsData: {
        items: [{ id: 'pin1', title: 'Pin 1', href: '/page1' }],
        ...props,
      },
      provide,
      stubs,
    });
  };

  const findList = () => wrapper.findByTestId('pinned-nav-items');
  const findEmptyHint = () => wrapper.findByText('Pin frequently used features for quick access.');

  describe('expanded', () => {
    describe('when cookie is not set', () => {
      it('is expanded by default', () => {
        createWrapper();
        expect(wrapper.findComponent(NavItem).isVisible()).toBe(true);
      });
    });

    describe('when cookie is set to false', () => {
      beforeEach(() => {
        Cookies.set(SIDEBAR_PINS_EXPANDED_COOKIE, 'false');
        createWrapper();
      });

      it('is collapsed', () => {
        expect(wrapper.findComponent(NavItem).isVisible()).toBe(false);
      });

      it('updates the cookie when expanding the section', async () => {
        findToggle().trigger('click');
        await nextTick();

        expect(setCookie).toHaveBeenCalledWith(SIDEBAR_PINS_EXPANDED_COOKIE, true, {
          expires: SIDEBAR_COOKIE_EXPIRATION,
        });
      });
    });

    describe('when cookie is set to true', () => {
      beforeEach(() => {
        Cookies.set(SIDEBAR_PINS_EXPANDED_COOKIE, 'true');
        createWrapper();
      });

      it('is expanded', () => {
        expect(wrapper.findComponent(NavItem).isVisible()).toBe(true);
      });

      it('updates the cookie when collapsing the section', async () => {
        findToggle().trigger('click');
        await nextTick();

        expect(setCookie).toHaveBeenCalledWith(SIDEBAR_PINS_EXPANDED_COOKIE, false, {
          expires: SIDEBAR_COOKIE_EXPIRATION,
        });
      });
    });

    describe('when a pinned nav item was used before', () => {
      beforeEach(() => {
        Cookies.set(SIDEBAR_PINS_EXPANDED_COOKIE, 'false');
        createWrapper({ wasPinnedNav: true });
      });

      it('is expanded', () => {
        expect(wrapper.findComponent(NavItem).isVisible()).toBe(true);
      });
    });

    describe('when rendered as a category group', () => {
      // is_active: true (current page is in this category) must not override storage.
      const groupItem = { id: 'code', title: 'Code', is_active: true };
      // Group state is scoped by panel type so the same category id in the
      // project and group sidebars persists independently.
      const groupKey = 'project-code';

      const createGroupWrapper = (props = {}) =>
        createWrapper({ groupItem, provide: { panelType: 'project' }, ...props });

      it('reads its collapse state from local storage, not the flat section cookie', () => {
        // Flat section cookie collapsed, group state untouched: the group stays expanded.
        Cookies.set(SIDEBAR_PINS_EXPANDED_COOKIE, 'false');
        createGroupWrapper();

        expect(wrapper.findComponent(NavItem).isVisible()).toBe(true);
      });

      it('is collapsed when its own group state is false', () => {
        setGroupStates({ [groupKey]: false });
        createGroupWrapper();

        expect(wrapper.findComponent(NavItem).isVisible()).toBe(false);
      });

      it('is expanded when collapsed but a pinned nav item in it was used before', () => {
        setGroupStates({ [groupKey]: false });
        createGroupWrapper({ wasPinnedNav: true });

        expect(wrapper.findComponent(NavItem).isVisible()).toBe(true);
      });

      it('keeps the same category independent across panels', () => {
        // The group panel collapsed "code"; the project panel's "code" is untouched.
        setGroupStates({ 'group-code': false });
        createGroupWrapper();

        expect(wrapper.findComponent(NavItem).isVisible()).toBe(true);
      });

      it('writes collapse state to its own group key without clobbering others', async () => {
        setGroupStates({ [groupKey]: true, 'project-docs': false });
        createGroupWrapper();

        findToggle().trigger('click');
        await nextTick();

        expect(getGroupStates()).toEqual({ [groupKey]: false, 'project-docs': false });
      });

      it('does not write the flat section cookie', async () => {
        createGroupWrapper();

        findToggle().trigger('click');
        await nextTick();

        expect(setCookie).not.toHaveBeenCalled();
      });

      // MenuSection re-syncs isExpanded to the real (collapsed) state when the
      // sidebar leaves icon-only mode, emitting collapse-toggle with a false
      // payload without any user interaction. The section must honor that
      // payload rather than blindly toggling, or a collapsed group's state
      // would flip to true and the group would wrongly reopen on next load.
      it('does not reopen a collapsed group when re-synced to collapsed', async () => {
        setGroupStates({ [groupKey]: false });
        createGroupWrapper();

        wrapper.findComponent(MenuSection).vm.$emit('collapse-toggle', false);
        await nextTick();

        expect(getGroupStates()).toMatchObject({ [groupKey]: false });
      });
    });
  });

  describe('hasFlyout prop', () => {
    describe.each([true, false])(`when %s`, (hasFlyout) => {
      beforeEach(() => {
        createWrapper({ hasFlyout });
      });

      it(`passes ${hasFlyout} to the section's hasFlyout prop`, () => {
        expect(wrapper.findComponent(MenuSection).props('hasFlyout')).toBe(hasFlyout);
      });
    });
  });

  describe('asyncCount prop', () => {
    it('passes asyncCount to MenuSection so the flyout shows correct pill counts when collapsed', () => {
      const asyncCount = { openIssuesCount: 5, openMergeRequestsCount: 3 };
      createWrapper({ asyncCount });

      expect(wrapper.findComponent(MenuSection).props('asyncCount')).toEqual(asyncCount);
    });

    it('passes empty asyncCount by default', () => {
      createWrapper();

      expect(wrapper.findComponent(MenuSection).props('asyncCount')).toEqual({});
    });
  });

  describe('ambiguous settings names', () => {
    it('get renamed to be unambiguous', () => {
      createWrapper({
        items: [
          { title: 'CI/CD', id: 'ci_cd' },
          { title: 'Merge requests', id: 'merge_request_settings' },
          { title: 'Monitor', id: 'monitor' },
          { title: 'Repository', id: 'repository' },
          { title: 'Repository', id: 'code' },
          { title: 'Something else', id: 'not_a_setting' },
        ],
      });

      expect(
        wrapper
          .findComponent(MenuSection)
          .props('item')
          .items.map((i) => i.title),
      ).toEqual([
        'CI/CD settings',
        'Merge requests settings',
        'Monitor settings',
        'Repository settings',
        'Repository',
        'Something else',
      ]);
    });
  });

  describe('supportsPins', () => {
    describe('when pins are supported', () => {
      beforeEach(() => {
        createWrapper({ supportsPins: true, stubs: { Draggable: stubComponent(Draggable) } });
      });

      it('wraps the pinned items in a draggable list', () => {
        expect(wrapper.findComponent(Draggable).exists()).toBe(true);
      });

      it('marks nav items as being in the pinned section', () => {
        expect(wrapper.findComponent(NavItem).props('isInPinnedSection')).toBe(true);
      });

      it('passes the items and drag configuration to the draggable list', () => {
        const draggable = wrapper.findComponent(Draggable);

        expect(draggable.props('value')).toEqual([{ id: 'pin1', title: 'Pin 1', href: '/page1' }]);
        expect(draggable.props('itemKey')).toBe('id');
        expect(draggable.attributes()).toMatchObject({
          handle: '.js-draggable-icon',
          tag: 'ul',
        });
      });
    });

    describe('when the draggable list emits a reordered list', () => {
      const pins = [
        { id: 'pin1', title: 'Pin 1', href: '/page1' },
        { id: 'pin2', title: 'Pin 2', href: '/page2' },
      ];

      beforeEach(() => {
        createWrapper({
          items: pins,
          supportsPins: true,
          stubs: { Draggable: stubComponent(Draggable) },
        });
        wrapper.findComponent(Draggable).vm.$emit('input', [pins[1], pins[0]]);
      });

      it('updates the rendered order', () => {
        const renderedIds = wrapper
          .findAllComponents(NavItem)
          .wrappers.map((w) => w.props('item').id);

        expect(renderedIds).toEqual(['pin2', 'pin1']);
      });
    });

    describe('when pins are not supported (default)', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('does not wrap the pinned items in a draggable list', () => {
        expect(wrapper.findComponent(Draggable).exists()).toBe(false);
      });

      it('renders the pinned items in a plain list element', () => {
        expect(findList().element.tagName).toBe('UL');
      });

      it('does not leak draggable configuration onto the list element', () => {
        const attributes = findList().attributes();

        expect(attributes.handle).toBeUndefined();
        expect(attributes.tag).toBeUndefined();
        expect(attributes['item-key']).toBeUndefined();
        expect(attributes.draggable).toBeUndefined();
      });

      it('does not mark nav items as being in the pinned section', () => {
        expect(wrapper.findComponent(NavItem).props('isInPinnedSection')).toBe(false);
      });
    });
  });

  describe('when there are no pinned items', () => {
    describe('by default', () => {
      beforeEach(() => {
        createWrapper({ items: [] });
      });

      it('shows the empty hint', () => {
        expect(findEmptyHint().exists()).toBe(true);
      });
    });

    describe('when headerless (unpinned items are hidden)', () => {
      beforeEach(() => {
        createWrapper({ items: [], headerless: true });
      });

      it('does not show the empty hint', () => {
        expect(findEmptyHint().exists()).toBe(false);
      });
    });

    describe('when the sidebar is collapsed to icons only', () => {
      beforeEach(() => {
        createWrapper({ items: [], provide: { isIconOnly: true } });
      });

      it('does not show the empty hint', () => {
        expect(findEmptyHint().exists()).toBe(false);
      });
    });
  });

  describe('click on a pinned nav item', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('stores pinned nav usage in sessionStorage', () => {
      expect(window.sessionStorage.getItem(PINNED_NAV_STORAGE_KEY)).toBe(null);
      wrapper.findComponent(NavItem).vm.$emit('nav-link-click');
      expect(window.sessionStorage.getItem(PINNED_NAV_STORAGE_KEY)).toBe('true');
    });
  });

  describe('when rendered as a category group', () => {
    const groupItem = { id: 'code', title: 'Code', is_active: true };

    beforeEach(() => {
      createWrapper({ groupItem });
    });

    it('uses the category title as the section header', () => {
      expect(wrapper.findComponent(MenuSection).props('item').title).toBe('Code');
    });

    it('renders the section header without an icon', () => {
      expect(wrapper.findComponent(MenuSection).props('item').icon).toBe(null);
    });

    it('renders the category title in a heavier font weight', () => {
      expect(wrapper.findComponent(MenuSection).props('boldTitle')).toBe(true);
    });

    it('labels the pinned list with the category title', () => {
      expect(findList().attributes('aria-label')).toBe('Code');
    });
  });

  describe('when not rendered as a category group', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('uses the thumbtack icon and Pinned title', () => {
      const item = wrapper.findComponent(MenuSection).props('item');

      expect(item.title).toBe('Pinned');
      expect(item.icon).toBe('thumbtack');
    });

    it('does not render the header in a heavier font weight', () => {
      expect(wrapper.findComponent(MenuSection).props('boldTitle')).toBe(false);
    });
  });
});
