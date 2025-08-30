import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SchemaIssuesSection from '~/admin/database_diagnostics/components/schema_issues_section.vue';
import { schemaIssuesResults, noSchemaIssuesResults } from '../mock_data';

describe('SchemaIssuesSection component', () => {
  let wrapper;

  const defaultProps = {
    databaseResults: schemaIssuesResults.schema_check_results.main,
  };

  const findNoIssuesAlert = () => wrapper.findByTestId('no-issues-alert');
  const findIndexesCount = () => wrapper.findByTestId('indexes-count');
  const findTablesCount = () => wrapper.findByTestId('tables-count');
  const findForeignKeysCount = () => wrapper.findByTestId('foreignKeys-count');
  const findSequencesCount = () => wrapper.findByTestId('sequences-count');
  const findIndexesToggle = () => wrapper.findByTestId('indexes-toggle');
  const findTablesToggle = () => wrapper.findByTestId('tables-toggle');
  const findForeignKeysToggle = () => wrapper.findByTestId('foreignKeys-toggle');
  const findSequencesToggle = () => wrapper.findByTestId('sequences-toggle');

  const findMissingSequencesCount = () => wrapper.findByTestId('missing-sequences-count');
  const findSequenceOwnershipCount = () => wrapper.findByTestId('sequence-ownership-count');
  const findSequenceOwnershipTable = () => wrapper.findByTestId('sequence-ownership-table');
  const findSequencesIssues = () => wrapper.findByTestId('sequences-issues');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(SchemaIssuesSection, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when no schema issues exist', () => {
    beforeEach(() => {
      createComponent({
        props: {
          databaseResults: noSchemaIssuesResults.schema_check_results.main,
        },
      });
    });

    it('displays success alert with correct message', () => {
      expect(findNoIssuesAlert().text()).toBe('No schema issues detected.');
      expect(findNoIssuesAlert().props('variant')).toBe('success');
      expect(findNoIssuesAlert().props('dismissible')).toBe(false);
    });

    it('shows success icon in alert', () => {
      const alert = findNoIssuesAlert();
      const icon = alert.findComponent(GlIcon);

      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe('check-circle-filled');
    });

    it('displays all section type labels', () => {
      expect(wrapper.text()).toContain('Indexes');
      expect(wrapper.text()).toContain('Tables');
      expect(wrapper.text()).toContain('Foreign keys');
      expect(wrapper.text()).toContain('Sequences');
    });

    it('does not show count badges for any sections', () => {
      expect(findIndexesCount().exists()).toBe(false);
      expect(findTablesCount().exists()).toBe(false);
      expect(findForeignKeysCount().exists()).toBe(false);
      expect(findSequencesCount().exists()).toBe(false);
    });

    it('does not show toggle buttons for any sections', () => {
      expect(findIndexesToggle().exists()).toBe(false);
      expect(findTablesToggle().exists()).toBe(false);
      expect(findForeignKeysToggle().exists()).toBe(false);
      expect(findSequencesToggle().exists()).toBe(false);
    });
  });

  describe('when schema issues exist', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not show success alert', () => {
      expect(findNoIssuesAlert().exists()).toBe(false);
    });

    it('displays correct count badges for sections with issues', () => {
      expect(findIndexesCount().text()).toBe('2');
      expect(findIndexesCount().props('variant')).toBe('warning');

      expect(findTablesCount().text()).toBe('1');
      expect(findTablesCount().props('variant')).toBe('warning');

      expect(findForeignKeysCount().text()).toBe('1');
      expect(findForeignKeysCount().props('variant')).toBe('warning');

      expect(findSequencesCount().text()).toBe('2'); // 1 missing + 1 ownership = 2
      expect(findSequencesCount().props('variant')).toBe('warning');
    });

    it('displays Details button text and proper configuration', () => {
      const toggleButtons = [
        findIndexesToggle(),
        findTablesToggle(),
        findForeignKeysToggle(),
        findSequencesToggle(),
      ];

      toggleButtons.forEach((button) => {
        expect(button.text()).toContain('Details');
        expect(button.props('category')).toBe('tertiary');
        expect(button.props('size')).toBe('small');
      });
    });

    it('shows mixed icon states when some sections have issues and others do not', () => {
      const mixedResults = {
        missing_indexes: [{ table_name: 'users' }],
        missing_tables: [],
        missing_foreign_keys: [{ table_name: 'merge_requests' }],
        missing_sequences: [],
      };

      createComponent({ props: { databaseResults: mixedResults } });

      const warningIcons = wrapper
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'warning');
      const successIcons = wrapper
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'check-circle-filled');

      expect(warningIcons).toHaveLength(2); // indexes and foreignKeys have issues
      expect(successIcons).toHaveLength(2); // tables and sequences have no issues
    });

    it('displays section labels', () => {
      expect(wrapper.text()).toContain('Indexes');
      expect(wrapper.text()).toContain('Tables');
      expect(wrapper.text()).toContain('Foreign keys');
      expect(wrapper.text()).toContain('Sequences');
    });

    it('renders subsections when main sequences section is expanded', async () => {
      wrapper = mountExtended(SchemaIssuesSection, {
        propsData: {
          databaseResults: schemaIssuesResults.schema_check_results.main,
        },
      });

      await findSequencesToggle().vm.$emit('click');
      await nextTick();

      const sequencesSection = findSequencesIssues();
      const sectionText = sequencesSection.text();
      const table = findSequenceOwnershipTable();

      expect(sectionText).toContain('Missing sequences');
      expect(findMissingSequencesCount().text()).toBe('1');
      expect(sectionText).toContain('Incorrect ownership');
      expect(findSequenceOwnershipCount().text()).toBe('1');

      expect(table.exists()).toBe(true);
      expect(sectionText).toContain('Sequence Name');
      expect(sectionText).toContain('Current Owner');
      expect(sectionText).toContain('Expected Owner');

      expect(sectionText).toContain('public.abuse_events_id_seq');
      expect(sectionText).toContain('public.achievements.id');
      expect(sectionText).toContain('public.abuse_events.id');

      expect(sectionText).toContain('users_id_seq');

      expect(sequencesSection.exists()).toBe(true);
      const dashIcons = sequencesSection
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'dash');
      expect(dashIcons).toHaveLength(1);
    });
  });
});
