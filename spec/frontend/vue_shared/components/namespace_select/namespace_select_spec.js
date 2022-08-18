import { nextTick } from 'vue';
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NamespaceSelect, {
  i18n,
  EMPTY_NAMESPACE_ID,
} from '~/vue_shared/components/namespace_select/namespace_select.vue';
import { userNamespaces, groupNamespaces } from './mock_data';

const FLAT_NAMESPACES = [...userNamespaces, ...groupNamespaces];
const EMPTY_NAMESPACE_TITLE = 'Empty namespace TEST';
const EMPTY_NAMESPACE_ITEM = { id: EMPTY_NAMESPACE_ID, humanName: EMPTY_NAMESPACE_TITLE };

describe('Namespace Select', () => {
  let wrapper;

  const createComponent = (props = {}) =>
    shallowMountExtended(NamespaceSelect, {
      propsData: {
        userNamespaces,
        groupNamespaces,
        ...props,
      },
      stubs: {
        // We have to "full" mount GlDropdown so that slot children will render
        GlDropdown,
      },
    });

  const wrappersText = (arr) => arr.wrappers.map((w) => w.text());
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownText = () => findDropdown().props('text');
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findGroupDropdownItems = () =>
    wrapper.findByTestId('namespace-list-groups').findAllComponents(GlDropdownItem);
  const findDropdownItemsTexts = () => findDropdownItems().wrappers.map((x) => x.text());
  const findSectionHeaders = () => wrapper.findAllComponents(GlDropdownSectionHeader);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const search = (term) => findSearchBox().vm.$emit('input', term);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('renders each dropdown item', () => {
      expect(findDropdownItemsTexts()).toEqual(FLAT_NAMESPACES.map((x) => x.humanName));
    });

    it('renders default dropdown text', () => {
      expect(findDropdownText()).toBe(i18n.DEFAULT_TEXT);
    });

    it('splits group and user namespaces', () => {
      const headers = findSectionHeaders();
      expect(wrappersText(headers)).toEqual([i18n.USERS, i18n.GROUPS]);
    });

    it('does not render wrapper as full width', () => {
      expect(findDropdown().attributes('block')).toBeUndefined();
    });
  });

  it('with defaultText, it overrides dropdown text', () => {
    const textOverride = 'Select an option';

    wrapper = createComponent({ defaultText: textOverride });

    expect(findDropdownText()).toBe(textOverride);
  });

  it('with includeHeaders=false, hides group/user headers', () => {
    wrapper = createComponent({ includeHeaders: false });

    expect(findSectionHeaders()).toHaveLength(0);
  });

  it('with fullWidth=true, sets the dropdown to full width', () => {
    wrapper = createComponent({ fullWidth: true });

    expect(findDropdown().attributes('block')).toBe('true');
  });

  describe('with search', () => {
    it.each`
      term           | includeEmptyNamespace | shouldFilterNamespaces | expectedItems
      ${''}          | ${false}              | ${true}                | ${[...userNamespaces, ...groupNamespaces]}
      ${'sub'}       | ${false}              | ${true}                | ${[groupNamespaces[1]]}
      ${'User'}      | ${false}              | ${true}                | ${[...userNamespaces]}
      ${'User'}      | ${true}               | ${true}                | ${[...userNamespaces]}
      ${'namespace'} | ${true}               | ${true}                | ${[EMPTY_NAMESPACE_ITEM, ...userNamespaces]}
      ${'sub'}       | ${false}              | ${false}               | ${[...userNamespaces, ...groupNamespaces]}
    `(
      'with term=$term, includeEmptyNamespace=$includeEmptyNamespace, and shouldFilterNamespaces=$shouldFilterNamespaces should show $expectedItems.length',
      async ({ term, includeEmptyNamespace, shouldFilterNamespaces, expectedItems }) => {
        wrapper = createComponent({
          includeEmptyNamespace,
          emptyNamespaceTitle: EMPTY_NAMESPACE_TITLE,
          shouldFilterNamespaces,
        });

        search(term);

        await nextTick();

        const expected = expectedItems.map((x) => x.humanName);

        expect(findDropdownItemsTexts()).toEqual(expected);
      },
    );
  });

  describe('when search is typed in', () => {
    it('emits `search` event', async () => {
      wrapper = createComponent();

      wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', 'foo');

      await nextTick();

      expect(wrapper.emitted('search')).toEqual([['foo']]);
    });
  });

  describe('with a selected namespace', () => {
    const selectedGroupIndex = 1;
    const selectedItem = groupNamespaces[selectedGroupIndex];

    beforeEach(() => {
      wrapper = createComponent();

      wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', 'foo');
      findGroupDropdownItems().at(selectedGroupIndex).vm.$emit('click');
    });

    it('sets the dropdown text', () => {
      expect(findDropdownText()).toBe(selectedItem.humanName);
    });

    it('emits the `select` event when a namespace is selected', () => {
      const args = [selectedItem];
      expect(wrapper.emitted('select')).toEqual([args]);
    });

    it('clears search', () => {
      expect(wrapper.findComponent(GlSearchBoxByType).props('value')).toBe('');
    });
  });

  describe('with an empty namespace option', () => {
    beforeEach(() => {
      wrapper = createComponent({
        includeEmptyNamespace: true,
        emptyNamespaceTitle: EMPTY_NAMESPACE_TITLE,
      });
    });

    it('includes the empty namespace', () => {
      const first = findDropdownItems().at(0);

      expect(first.text()).toBe(EMPTY_NAMESPACE_TITLE);
    });

    it('emits the `select` event when a namespace is selected', () => {
      findDropdownItems().at(0).vm.$emit('click');

      expect(wrapper.emitted('select')).toEqual([[EMPTY_NAMESPACE_ITEM]]);
    });

    it.each`
      desc                          | term       | shouldShow
      ${'should hide empty option'} | ${'group'} | ${false}
      ${'should show empty option'} | ${'Empty'} | ${true}
    `('when search for $term, $desc', async ({ term, shouldShow }) => {
      search(term);

      await nextTick();

      expect(findDropdownItemsTexts().includes(EMPTY_NAMESPACE_TITLE)).toBe(shouldShow);
    });
  });

  describe('when `hasNextPageOfGroups` prop is `true`', () => {
    it('renders `GlIntersectionObserver` and emits `load-more-groups` event when bottom is reached', () => {
      wrapper = createComponent({ hasNextPageOfGroups: true });

      const intersectionObserver = wrapper.findComponent(GlIntersectionObserver);

      intersectionObserver.vm.$emit('appear');

      expect(intersectionObserver.exists()).toBe(true);
      expect(wrapper.emitted('load-more-groups')).toEqual([[]]);
    });

    describe('when `isLoadingMoreGroups` prop is `true`', () => {
      it('renders a loading icon', () => {
        wrapper = createComponent({ hasNextPageOfGroups: true, isLoadingMoreGroups: true });

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });
    });
  });

  describe('when `isSearchLoading` prop is `true`', () => {
    it('sets `isLoading` prop to `true`', () => {
      wrapper = createComponent({ isSearchLoading: true });

      expect(wrapper.findComponent(GlSearchBoxByType).props('isLoading')).toBe(true);
    });
  });
});
