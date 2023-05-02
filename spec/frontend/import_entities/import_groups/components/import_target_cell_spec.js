import { GlDropdownItem, GlFormInput } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ImportGroupDropdown from '~/import_entities/components/group_dropdown.vue';
import { STATUSES } from '~/import_entities/constants';
import ImportTargetCell from '~/import_entities/import_groups/components/import_target_cell.vue';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchNamespacesWhereUserCanImportProjectsQuery from '~/import_entities/import_projects/graphql/queries/search_namespaces_where_user_can_import_projects.query.graphql';

import {
  generateFakeEntry,
  availableNamespacesFixture,
  AVAILABLE_NAMESPACES,
} from '../graphql/fixtures';

Vue.use(VueApollo);

const generateFakeTableEntry = ({ flags = {}, ...config }) => {
  const entry = generateFakeEntry(config);

  return {
    ...entry,
    importTarget: {
      targetNamespace: AVAILABLE_NAMESPACES[0],
      newName: entry.lastImportTarget.newName,
    },
    flags,
  };
};

describe('import target cell', () => {
  let wrapper;
  let apolloProvider;
  let group;

  const findNameInput = () => wrapper.findComponent(GlFormInput);
  const findNamespaceDropdown = () => wrapper.findComponent(ImportGroupDropdown);

  const createComponent = (props) => {
    apolloProvider = createMockApollo([
      [
        searchNamespacesWhereUserCanImportProjectsQuery,
        () => Promise.resolve(availableNamespacesFixture),
      ],
    ]);

    wrapper = shallowMount(ImportTargetCell, {
      apolloProvider,
      stubs: { ImportGroupDropdown },
      propsData: {
        groupPathRegex: /.*/,
        ...props,
      },
    });
  };

  describe('events', () => {
    beforeEach(async () => {
      group = generateFakeTableEntry({ id: 1, status: STATUSES.NONE });
      createComponent({ group });
      await nextTick();
      jest.advanceTimersByTime(DEBOUNCE_DELAY);
      await nextTick();
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
      expect(wrapper.emitted('update-target-namespace')[0][0]).toStrictEqual(
        AVAILABLE_NAMESPACES[1],
      );
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

  it('renders both no parent option and available namespaces list when available namespaces list is not empty', async () => {
    createComponent({
      group: generateFakeTableEntry({ id: 1, status: STATUSES.NONE }),
    });
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await waitForPromises();
    await nextTick();

    const [firstItem, ...rest] = findNamespaceDropdown()
      .findAllComponents(GlDropdownItem)
      .wrappers.map((w) => w.text());

    expect(firstItem).toBe('No parent');
    expect(rest).toHaveLength(AVAILABLE_NAMESPACES.length);
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
