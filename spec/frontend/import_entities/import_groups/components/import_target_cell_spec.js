import { GlDropdownItem, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ImportGroupDropdown from '~/import_entities/components/group_dropdown.vue';
import { STATUSES } from '~/import_entities/constants';
import ImportTargetCell from '~/import_entities/import_groups/components/import_target_cell.vue';
import { generateFakeEntry, availableNamespacesFixture } from '../graphql/fixtures';

const generateFakeTableEntry = ({ flags = {}, ...config }) => {
  const entry = generateFakeEntry(config);

  return {
    ...entry,
    importTarget: {
      targetNamespace: availableNamespacesFixture[0],
      newName: entry.lastImportTarget.newName,
    },
    flags,
  };
};

describe('import target cell', () => {
  let wrapper;
  let group;

  const findNameInput = () => wrapper.findComponent(GlFormInput);
  const findNamespaceDropdown = () => wrapper.findComponent(ImportGroupDropdown);

  const createComponent = (props) => {
    wrapper = shallowMount(ImportTargetCell, {
      stubs: { ImportGroupDropdown },
      propsData: {
        availableNamespaces: availableNamespacesFixture,
        groupPathRegex: /.*/,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('events', () => {
    beforeEach(() => {
      group = generateFakeTableEntry({ id: 1, status: STATUSES.NONE });
      createComponent({ group });
    });

    it('emits update-new-name when input value is changed', () => {
      findNameInput().vm.$emit('input', 'demo');
      expect(wrapper.emitted('update-new-name')).toBeDefined();
      expect(wrapper.emitted('update-new-name')[0][0]).toBe('demo');
    });

    it('emits update-target-namespace when dropdown option is clicked', () => {
      const dropdownItem = findNamespaceDropdown().findAllComponents(GlDropdownItem).at(2);

      dropdownItem.vm.$emit('click');

      expect(wrapper.emitted('update-target-namespace')).toBeDefined();
      expect(wrapper.emitted('update-target-namespace')[0][0]).toBe(availableNamespacesFixture[1]);
    });
  });

  describe('when entity status is NONE', () => {
    beforeEach(() => {
      group = generateFakeTableEntry({
        id: 1,
        status: STATUSES.NONE,
        flags: {
          isAvailableForImport: true,
        },
      });
      createComponent({ group });
    });

    it('renders namespace dropdown as not disabled', () => {
      expect(findNamespaceDropdown().attributes('disabled')).toBe(undefined);
    });
  });

  it('renders only no parent option if available namespaces list is empty', () => {
    createComponent({
      group: generateFakeTableEntry({ id: 1, status: STATUSES.NONE }),
      availableNamespaces: [],
    });

    const items = findNamespaceDropdown()
      .findAllComponents(GlDropdownItem)
      .wrappers.map((w) => w.text());

    expect(items[0]).toBe('No parent');
    expect(items).toHaveLength(1);
  });

  it('renders both no parent option and available namespaces list when available namespaces list is not empty', () => {
    createComponent({
      group: generateFakeTableEntry({ id: 1, status: STATUSES.NONE }),
      availableNamespaces: availableNamespacesFixture,
    });

    const [firstItem, ...rest] = findNamespaceDropdown()
      .findAllComponents(GlDropdownItem)
      .wrappers.map((w) => w.text());

    expect(firstItem).toBe('No parent');
    expect(rest).toHaveLength(availableNamespacesFixture.length);
  });

  describe('when entity is not available for import', () => {
    beforeEach(() => {
      group = generateFakeTableEntry({
        id: 1,
        flags: { isAvailableForImport: false },
      });
      createComponent({ group });
    });

    it('renders namespace dropdown as disabled', () => {
      expect(findNamespaceDropdown().attributes('disabled')).toBe('true');
    });
  });

  describe('when entity is available for import', () => {
    const FAKE_PROGRESS_MESSAGE = 'progress message';
    beforeEach(() => {
      group = generateFakeTableEntry({
        id: 1,
        flags: { isAvailableForImport: true },
        progress: { message: FAKE_PROGRESS_MESSAGE },
      });
      createComponent({ group });
    });

    it('renders namespace dropdown as enabled', () => {
      expect(findNamespaceDropdown().attributes('disabled')).toBe(undefined);
    });

    it('renders progress message as error if it exists', () => {
      expect(wrapper.find('[role=alert]').text()).toBe(FAKE_PROGRESS_MESSAGE);
    });
  });
});
