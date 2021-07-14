import { GlButton, GlDropdownItem, GlLink, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import ImportGroupDropdown from '~/import_entities/components/group_dropdown.vue';
import { STATUSES } from '~/import_entities/constants';
import ImportTableRow from '~/import_entities/import_groups/components/import_table_row.vue';
import addValidationErrorMutation from '~/import_entities/import_groups/graphql/mutations/add_validation_error.mutation.graphql';
import removeValidationErrorMutation from '~/import_entities/import_groups/graphql/mutations/remove_validation_error.mutation.graphql';
import groupAndProjectQuery from '~/import_entities/import_groups/graphql/queries/groupAndProject.query.graphql';
import { availableNamespacesFixture } from '../graphql/fixtures';

Vue.use(VueApollo);

const { i18n: I18N } = ImportTableRow;

const getFakeGroup = (status) => ({
  web_url: 'https://fake.host/',
  full_path: 'fake_group_1',
  full_name: 'fake_name_1',
  import_target: {
    target_namespace: 'root',
    new_name: 'group1',
  },
  id: 1,
  validation_errors: [],
  progress: { status },
});

const EXISTING_GROUP_TARGET_NAMESPACE = 'existing-group';
const EXISTING_GROUP_PATH = 'existing-path';
const EXISTING_PROJECT_PATH = 'existing-project-path';

describe('import table row', () => {
  let wrapper;
  let apolloProvider;
  let group;

  const findByText = (cmp, text) => {
    return wrapper.findAll(cmp).wrappers.find((node) => node.text().indexOf(text) === 0);
  };
  const findImportButton = () => findByText(GlButton, 'Import');
  const findNameInput = () => wrapper.find(GlFormInput);
  const findNamespaceDropdown = () => wrapper.find(ImportGroupDropdown);

  const createComponent = (props) => {
    apolloProvider = createMockApollo([
      [
        groupAndProjectQuery,
        ({ fullPath }) => {
          const existingGroup =
            fullPath === `${EXISTING_GROUP_TARGET_NAMESPACE}/${EXISTING_GROUP_PATH}`
              ? { id: 1 }
              : null;

          const existingProject =
            fullPath === `${EXISTING_GROUP_TARGET_NAMESPACE}/${EXISTING_PROJECT_PATH}`
              ? { id: 1 }
              : null;

          return Promise.resolve({ data: { existingGroup, existingProject } });
        },
      ],
    ]);

    wrapper = shallowMount(ImportTableRow, {
      apolloProvider,
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
      group = getFakeGroup(STATUSES.NONE);
      createComponent({ group });
    });

    it.each`
      selector            | sourceEvent | payload      | event
      ${findNameInput}    | ${'input'}  | ${'demo'}    | ${'update-new-name'}
      ${findImportButton} | ${'click'}  | ${undefined} | ${'import-group'}
    `('invokes $event', ({ selector, sourceEvent, payload, event }) => {
      selector().vm.$emit(sourceEvent, payload);
      expect(wrapper.emitted(event)).toBeDefined();
      expect(wrapper.emitted(event)[0][0]).toBe(payload);
    });

    it('emits update-target-namespace when dropdown option is clicked', () => {
      const dropdownItem = findNamespaceDropdown().findAllComponents(GlDropdownItem).at(2);
      const dropdownItemText = dropdownItem.text();

      dropdownItem.vm.$emit('click');

      expect(wrapper.emitted('update-target-namespace')).toBeDefined();
      expect(wrapper.emitted('update-target-namespace')[0][0]).toBe(dropdownItemText);
    });
  });

  describe('when entity status is NONE', () => {
    beforeEach(() => {
      group = getFakeGroup(STATUSES.NONE);
      createComponent({ group });
    });

    it('renders Import button', () => {
      expect(findByText(GlButton, 'Import').exists()).toBe(true);
    });

    it('renders namespace dropdown as not disabled', () => {
      expect(findNamespaceDropdown().attributes('disabled')).toBe(undefined);
    });
  });

  it('renders only no parent option if available namespaces list is empty', () => {
    createComponent({
      group: getFakeGroup(STATUSES.NONE),
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
      group: getFakeGroup(STATUSES.NONE),
      availableNamespaces: availableNamespacesFixture,
    });

    const [firstItem, ...rest] = findNamespaceDropdown()
      .findAllComponents(GlDropdownItem)
      .wrappers.map((w) => w.text());

    expect(firstItem).toBe('No parent');
    expect(rest).toHaveLength(availableNamespacesFixture.length);
  });

  describe('when entity status is SCHEDULING', () => {
    beforeEach(() => {
      group = getFakeGroup(STATUSES.SCHEDULING);
      createComponent({ group });
    });

    it('does not render Import button', () => {
      expect(findByText(GlButton, 'Import')).toBe(undefined);
    });

    it('renders namespace dropdown as disabled', () => {
      expect(findNamespaceDropdown().attributes('disabled')).toBe('true');
    });
  });

  describe('when entity status is FINISHED', () => {
    beforeEach(() => {
      group = getFakeGroup(STATUSES.FINISHED);
      createComponent({ group });
    });

    it('does not render Import button', () => {
      expect(findByText(GlButton, 'Import')).toBe(undefined);
    });

    it('does not render namespace dropdown', () => {
      expect(findNamespaceDropdown().exists()).toBe(false);
    });

    it('renders target as link', () => {
      const TARGET_LINK = `${group.import_target.target_namespace}/${group.import_target.new_name}`;
      expect(findByText(GlLink, TARGET_LINK).exists()).toBe(true);
    });
  });

  describe('validations', () => {
    it('reports invalid group name when name is not matching regex', () => {
      createComponent({
        group: {
          ...getFakeGroup(STATUSES.NONE),
          import_target: {
            target_namespace: 'root',
            new_name: 'very`bad`name',
          },
        },
        groupPathRegex: /^[a-zA-Z]+$/,
      });

      expect(wrapper.text()).toContain('Please choose a group URL with no special characters.');
    });

    it('reports invalid group name if relevant validation error exists', async () => {
      const FAKE_ERROR_MESSAGE = 'fake error';

      createComponent({
        group: {
          ...getFakeGroup(STATUSES.NONE),
          validation_errors: [
            {
              field: 'new_name',
              message: FAKE_ERROR_MESSAGE,
            },
          ],
        },
      });

      jest.runOnlyPendingTimers();
      await nextTick();

      expect(wrapper.text()).toContain(FAKE_ERROR_MESSAGE);
    });

    it('sets validation error when targetting existing group', async () => {
      const testGroup = getFakeGroup(STATUSES.NONE);

      createComponent({
        group: {
          ...testGroup,
          import_target: {
            target_namespace: EXISTING_GROUP_TARGET_NAMESPACE,
            new_name: EXISTING_GROUP_PATH,
          },
        },
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate');

      jest.runOnlyPendingTimers();
      await nextTick();

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: addValidationErrorMutation,
        variables: {
          field: 'new_name',
          message: I18N.NAME_ALREADY_EXISTS,
          sourceGroupId: testGroup.id,
        },
      });
    });

    it('sets validation error when targetting existing project', async () => {
      const testGroup = getFakeGroup(STATUSES.NONE);

      createComponent({
        group: {
          ...testGroup,
          import_target: {
            target_namespace: EXISTING_GROUP_TARGET_NAMESPACE,
            new_name: EXISTING_PROJECT_PATH,
          },
        },
      });

      jest.spyOn(wrapper.vm.$apollo, 'mutate');

      jest.runOnlyPendingTimers();
      await nextTick();

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: addValidationErrorMutation,
        variables: {
          field: 'new_name',
          message: I18N.NAME_ALREADY_EXISTS,
          sourceGroupId: testGroup.id,
        },
      });
    });

    it('clears validation error when target is updated', async () => {
      const testGroup = getFakeGroup(STATUSES.NONE);

      createComponent({
        group: {
          ...testGroup,
          import_target: {
            target_namespace: EXISTING_GROUP_TARGET_NAMESPACE,
            new_name: EXISTING_PROJECT_PATH,
          },
        },
      });

      jest.runOnlyPendingTimers();
      await nextTick();

      jest.spyOn(wrapper.vm.$apollo, 'mutate');

      await wrapper.setProps({
        group: {
          ...testGroup,
          import_target: {
            target_namespace: 'valid_namespace',
            new_name: 'valid_path',
          },
        },
      });

      jest.runOnlyPendingTimers();
      await nextTick();

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: removeValidationErrorMutation,
        variables: {
          field: 'new_name',
          sourceGroupId: testGroup.id,
        },
      });
    });
  });
});
