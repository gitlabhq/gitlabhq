import { nextTick } from 'vue';
import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NamespaceSelect, {
  i18n,
  EMPTY_NAMESPACE_ID,
} from '~/vue_shared/components/namespace_select/namespace_select.vue';
import { user, group, namespaces } from './mock_data';

const FLAT_NAMESPACES = [...group, ...user];
const EMPTY_NAMESPACE_TITLE = 'Empty namespace TEST';
const EMPTY_NAMESPACE_ITEM = { id: EMPTY_NAMESPACE_ID, humanName: EMPTY_NAMESPACE_TITLE };

describe('Namespace Select', () => {
  let wrapper;

  const createComponent = (props = {}) =>
    shallowMountExtended(NamespaceSelect, {
      propsData: {
        data: namespaces,
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
      expect(wrappersText(headers)).toEqual([i18n.GROUPS, i18n.USERS]);
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
      term           | includeEmptyNamespace | expectedItems
      ${''}          | ${false}              | ${[...namespaces.group, ...namespaces.user]}
      ${'sub'}       | ${false}              | ${[namespaces.group[1]]}
      ${'User'}      | ${false}              | ${[...namespaces.user]}
      ${'User'}      | ${true}               | ${[...namespaces.user]}
      ${'namespace'} | ${true}               | ${[EMPTY_NAMESPACE_ITEM, ...namespaces.user]}
    `(
      'with term=$term and includeEmptyNamespace=$includeEmptyNamespace, should show $expectedItems.length',
      async ({ term, includeEmptyNamespace, expectedItems }) => {
        wrapper = createComponent({
          includeEmptyNamespace,
          emptyNamespaceTitle: EMPTY_NAMESPACE_TITLE,
        });

        search(term);

        await nextTick();

        const expected = expectedItems.map((x) => x.humanName);

        expect(findDropdownItemsTexts()).toEqual(expected);
      },
    );
  });

  describe('with a selected namespace', () => {
    const selectedGroupIndex = 1;
    const selectedItem = group[selectedGroupIndex];

    beforeEach(() => {
      wrapper = createComponent();

      findDropdownItems().at(selectedGroupIndex).vm.$emit('click');
    });

    it('sets the dropdown text', () => {
      expect(findDropdownText()).toBe(selectedItem.humanName);
    });

    it('emits the `select` event when a namespace is selected', () => {
      const args = [selectedItem];
      expect(wrapper.emitted('select')).toEqual([args]);
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
});
