import { nextTick } from 'vue';
import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NamespaceSelect, {
  i18n,
  EMPTY_NAMESPACE_ID,
} from '~/vue_shared/components/namespace_select/namespace_select.vue';
import { user, group, namespaces } from './mock_data';

describe('Namespace Select', () => {
  let wrapper;

  const createComponent = (props = {}) =>
    shallowMountExtended(NamespaceSelect, {
      propsData: {
        data: namespaces,
        ...props,
      },
    });

  const wrappersText = (arr) => arr.wrappers.map((w) => w.text());
  const flatNamespaces = () => [...group, ...user];
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownAttributes = (attr) => findDropdown().attributes(attr);
  const selectedDropdownItemText = () => findDropdownAttributes('text');
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findSectionHeaders = () => wrapper.findAllComponents(GlDropdownSectionHeader);

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the dropdown', () => {
    expect(findDropdown().exists()).toBe(true);
  });

  it('can override the default text', () => {
    const textOverride = 'Select an option';
    wrapper = createComponent({ defaultText: textOverride });
    expect(selectedDropdownItemText()).toBe(textOverride);
  });

  it('renders each dropdown item', () => {
    const items = findDropdownItems().wrappers;
    expect(items).toHaveLength(flatNamespaces().length);
  });

  it('renders the human name for each item', () => {
    const dropdownItems = wrappersText(findDropdownItems());
    const flatNames = flatNamespaces().map(({ humanName }) => humanName);
    expect(dropdownItems).toEqual(flatNames);
  });

  it('sets the initial dropdown text', () => {
    expect(selectedDropdownItemText()).toBe(i18n.DEFAULT_TEXT);
  });

  it('splits group and user namespaces', () => {
    const headers = findSectionHeaders();
    expect(headers).toHaveLength(2);
    expect(wrappersText(headers)).toEqual([i18n.GROUPS, i18n.USERS]);
  });

  it('can hide the group / user headers', () => {
    wrapper = createComponent({ includeHeaders: false });
    expect(findSectionHeaders()).toHaveLength(0);
  });

  it('sets the dropdown to full width', () => {
    expect(findDropdownAttributes('block')).toBeUndefined();

    wrapper = createComponent({ fullWidth: true });

    expect(findDropdownAttributes('block')).not.toBeUndefined();
    expect(findDropdownAttributes('block')).toBe('true');
  });

  describe('with a selected namespace', () => {
    const selectedGroupIndex = 1;
    const selectedItem = group[selectedGroupIndex];

    beforeEach(() => {
      findDropdownItems().at(selectedGroupIndex).vm.$emit('click');
    });

    it('sets the dropdown text', () => {
      expect(selectedDropdownItemText()).toBe(selectedItem.humanName);
    });

    it('emits the `select` event when a namespace is selected', () => {
      const args = [selectedItem];
      expect(wrapper.emitted('select')).toEqual([args]);
    });
  });

  describe('with an empty namespace option', () => {
    const emptyNamespaceTitle = 'No namespace selected';

    beforeEach(async () => {
      wrapper = createComponent({
        includeEmptyNamespace: true,
        emptyNamespaceTitle,
      });
      await nextTick();
    });

    it('includes the empty namespace', () => {
      const first = findDropdownItems().at(0);
      expect(first.text()).toBe(emptyNamespaceTitle);
    });

    it('emits the `select` event when a namespace is selected', () => {
      findDropdownItems().at(0).vm.$emit('click');

      expect(wrapper.emitted('select')).toEqual([
        [{ id: EMPTY_NAMESPACE_ID, humanName: emptyNamespaceTitle }],
      ]);
    });
  });
});
