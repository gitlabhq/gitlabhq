import { shallowMount } from '@vue/test-utils';
import { GlButton, GlLink, GlFormInput } from '@gitlab/ui';
import Select2Select from '~/vue_shared/components/select2_select.vue';
import ImportTableRow from '~/import_entities/import_groups/components/import_table_row.vue';
import { STATUSES } from '~/import_entities/constants';
import { availableNamespacesFixture } from '../graphql/fixtures';

const getFakeGroup = (status) => ({
  web_url: 'https://fake.host/',
  full_path: 'fake_group_1',
  full_name: 'fake_name_1',
  import_target: {
    target_namespace: 'root',
    new_name: 'group1',
  },
  id: 1,
  status,
});

describe('import table row', () => {
  let wrapper;
  let group;

  const findByText = (cmp, text) => {
    return wrapper.findAll(cmp).wrappers.find((node) => node.text().indexOf(text) === 0);
  };
  const findImportButton = () => findByText(GlButton, 'Import');
  const findNameInput = () => wrapper.find(GlFormInput);
  const findNamespaceDropdown = () => wrapper.find(Select2Select);

  const createComponent = (props) => {
    wrapper = shallowMount(ImportTableRow, {
      propsData: {
        availableNamespaces: availableNamespacesFixture,
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
      selector                 | sourceEvent | payload      | event
      ${findNamespaceDropdown} | ${'input'}  | ${'demo'}    | ${'update-target-namespace'}
      ${findNameInput}         | ${'input'}  | ${'demo'}    | ${'update-new-name'}
      ${findImportButton}      | ${'click'}  | ${undefined} | ${'import-group'}
    `('invokes $event', ({ selector, sourceEvent, payload, event }) => {
      selector().vm.$emit(sourceEvent, payload);
      expect(wrapper.emitted(event)).toBeDefined();
      expect(wrapper.emitted(event)[0][0]).toBe(payload);
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
});
