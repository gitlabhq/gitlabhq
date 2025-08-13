import { GlIcon, GlBadge, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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

    it('shows success icons for all sections', () => {
      const successIcons = wrapper
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'check-circle-filled');
      expect(successIcons.length).toBeGreaterThan(0);
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

      expect(findSequencesCount().text()).toBe('1');
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

    it('shows success icons when sections have no issues', () => {
      createComponent({
        props: {
          databaseResults: noSchemaIssuesResults.schema_check_results.main,
        },
      });

      const successIcons = wrapper
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'check-circle-filled');
      expect(successIcons.length).toBeGreaterThan(0);
    });

    it('shows warning icons for sections with issues', () => {
      const warningIcons = wrapper
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'warning');
      expect(warningIcons).toHaveLength(4); // All 4 sections have issues in main DB
    });

    it('displays chevron-down icons in toggle buttons', () => {
      const chevronIcons = wrapper
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'chevron-down');
      expect(chevronIcons.length).toBeGreaterThan(0);
    });

    it('displays section labels', () => {
      expect(wrapper.text()).toContain('Indexes');
      expect(wrapper.text()).toContain('Tables');
      expect(wrapper.text()).toContain('Foreign keys');
      expect(wrapper.text()).toContain('Sequences');
    });
  });

  describe('component behavior with different data', () => {
    it('handles string-type issues', () => {
      const databaseResultsWithStrings = {
        missing_indexes: ['simple_index_name', 'another_index'],
        missing_tables: [],
        missing_foreign_keys: [],
        missing_sequences: [],
      };

      createComponent({ props: { databaseResults: databaseResultsWithStrings } });

      expect(findIndexesCount().text()).toBe('2');
      expect(findTablesCount().exists()).toBe(false);
      expect(findForeignKeysCount().exists()).toBe(false);
      expect(findSequencesCount().exists()).toBe(false);
    });

    it('handles object-type issues with structured data', () => {
      createComponent();

      // Verify that component displays the expected counts
      expect(findIndexesCount().text()).toBe('2');
      expect(findTablesCount().text()).toBe('1');
      expect(findForeignKeysCount().text()).toBe('1');
      expect(findSequencesCount().text()).toBe('1');
    });

    it('handles mixed data with some sections having issues', () => {
      const mixedResults = {
        missing_indexes: [{ table_name: 'users', column_name: 'email' }],
        missing_tables: [],
        missing_foreign_keys: [],
        missing_sequences: [{ sequence_name: 'test_seq' }],
      };

      createComponent({ props: { databaseResults: mixedResults } });

      expect(findIndexesCount().text()).toBe('1');
      expect(findTablesCount().exists()).toBe(false);
      expect(findForeignKeysCount().exists()).toBe(false);
      expect(findSequencesCount().text()).toBe('1');
    });
  });

  describe('edge cases and data handling', () => {
    it('handles incomplete database results gracefully', () => {
      const incompleteResults = {
        missing_indexes: [{ table_name: 'test' }],
        missing_tables: [],
        // missing_foreign_keys and missing_sequences intentionally omitted
      };

      createComponent({ props: { databaseResults: incompleteResults } });

      expect(wrapper.text()).toContain('Indexes');
      expect(wrapper.text()).toContain('Tables');
      expect(wrapper.text()).toContain('Foreign keys');
      expect(wrapper.text()).toContain('Sequences');

      expect(findIndexesCount().text()).toBe('1');
      expect(findTablesCount().exists()).toBe(false);
    });

    it('handles empty arrays gracefully', () => {
      const emptyResults = {
        missing_indexes: [],
        missing_tables: [],
        missing_foreign_keys: [],
        missing_sequences: [],
      };

      createComponent({ props: { databaseResults: emptyResults } });

      expect(findNoIssuesAlert().exists()).toBe(true);
      expect(findNoIssuesAlert().text()).toBe('No schema issues detected.');
    });

    it('handles completely empty object', () => {
      createComponent({ props: { databaseResults: {} } });

      expect(wrapper.text()).toContain('Indexes');
      expect(wrapper.text()).toContain('Tables');
      expect(wrapper.text()).toContain('Foreign keys');
      expect(wrapper.text()).toContain('Sequences');
    });
  });

  describe('component interface', () => {
    it('renders without crashing with minimal data', () => {
      const minimalResults = {
        missing_indexes: [],
        missing_tables: [],
        missing_foreign_keys: [],
        missing_sequences: [],
      };

      expect(() => {
        createComponent({ props: { databaseResults: minimalResults } });
      }).not.toThrow();

      expect(wrapper.text()).toContain('No schema issues detected.');
    });

    it('maintains consistent behavior across different data states', () => {
      // Test with issues
      createComponent();
      expect(wrapper.text()).toContain('Indexes');
      expect(wrapper.text()).toContain('Details');

      // Test without issues
      createComponent({
        props: {
          databaseResults: noSchemaIssuesResults.schema_check_results.main,
        },
      });
      expect(wrapper.text()).toContain('Indexes');
      expect(wrapper.text()).toContain('No schema issues detected');
    });

    it('renders expected number of components for each data state', () => {
      // With issues - should have badges and buttons
      createComponent();
      const badgesWithIssues = wrapper.findAllComponents(GlBadge);
      const buttonsWithIssues = wrapper.findAllComponents(GlButton);
      expect(badgesWithIssues).toHaveLength(4); // One for each section with issues
      expect(buttonsWithIssues).toHaveLength(4); // One toggle for each section with issues

      // Without issues - should have no badges or buttons
      createComponent({
        props: {
          databaseResults: noSchemaIssuesResults.schema_check_results.main,
        },
      });
      const badgesWithoutIssues = wrapper.findAllComponents(GlBadge);
      const buttonsWithoutIssues = wrapper.findAllComponents(GlButton);
      expect(badgesWithoutIssues).toHaveLength(0);
      expect(buttonsWithoutIssues).toHaveLength(0);
    });

    it('uses proper component variants for different states', () => {
      createComponent();

      // Warning badges for issues
      const warningBadges = wrapper
        .findAllComponents(GlBadge)
        .wrappers.filter((badge) => badge.props('variant') === 'warning');
      expect(warningBadges).toHaveLength(4);

      // Tertiary buttons for toggles
      const tertiaryButtons = wrapper
        .findAllComponents(GlButton)
        .wrappers.filter((button) => button.props('category') === 'tertiary');
      expect(tertiaryButtons).toHaveLength(4);
    });

    it('provides appropriate icon indicators for different states', () => {
      // Test with data that has mixed states (some issues, some clean)
      const mixedResults = {
        missing_indexes: [{ table_name: 'users' }], // Has issues
        missing_tables: [], // No issues
        missing_foreign_keys: [], // No issues
        missing_sequences: [{ sequence_name: 'test_seq' }], // Has issues
      };

      createComponent({ props: { databaseResults: mixedResults } });

      const allIcons = wrapper.findAllComponents(GlIcon);
      expect(allIcons.length).toBeGreaterThan(0);

      // Check for warning icons (sections with issues)
      const warningIcons = allIcons.wrappers.filter((icon) => icon.props('name') === 'warning');
      expect(warningIcons).toHaveLength(2); // indexes and sequences have issues

      // Check for success icons (sections without issues)
      const successIcons = allIcons.wrappers.filter(
        (icon) => icon.props('name') === 'check-circle-filled',
      );
      expect(successIcons).toHaveLength(2); // tables and foreign_keys have no issues
    });
  });

  describe('data handling variations', () => {
    it('displays correct counts for different issue types', () => {
      createComponent();

      // Based on mock data structure
      expect(findIndexesCount().text()).toBe('2');
      expect(findTablesCount().text()).toBe('1');
      expect(findForeignKeysCount().text()).toBe('1');
      expect(findSequencesCount().text()).toBe('1');
    });

    it('handles arrays of different types', () => {
      const mixedTypeResults = {
        missing_indexes: ['string_index', { table_name: 'obj_table', column_name: 'obj_col' }],
        missing_tables: [],
        missing_foreign_keys: [],
        missing_sequences: [],
      };

      createComponent({ props: { databaseResults: mixedTypeResults } });

      expect(findIndexesCount().text()).toBe('2');
      expect(findIndexesToggle().exists()).toBe(true);
    });

    it('shows appropriate visual feedback based on data presence', () => {
      // Test with mixed data - some sections with issues, some without
      const mixedResults = {
        missing_indexes: [{ table_name: 'users' }],
        missing_tables: [],
        missing_foreign_keys: [{ table_name: 'merge_requests' }],
        missing_sequences: [],
      };

      createComponent({ props: { databaseResults: mixedResults } });

      // Sections with issues should show badges and toggles
      expect(findIndexesCount().exists()).toBe(true);
      expect(findIndexesToggle().exists()).toBe(true);
      expect(findForeignKeysCount().exists()).toBe(true);
      expect(findForeignKeysToggle().exists()).toBe(true);

      // Sections without issues should not show badges or toggles
      expect(findTablesCount().exists()).toBe(false);
      expect(findTablesToggle().exists()).toBe(false);
      expect(findSequencesCount().exists()).toBe(false);
      expect(findSequencesToggle().exists()).toBe(false);
    });
  });

  describe('component configuration and props', () => {
    it('configures toggle buttons correctly when issues exist', () => {
      createComponent();

      const toggleButtons = wrapper.findAllComponents(GlButton);
      expect(toggleButtons).toHaveLength(4);

      toggleButtons.wrappers.forEach((button) => {
        expect(button.props('category')).toBe('tertiary');
        expect(button.props('size')).toBe('small');
        expect(button.text()).toContain('Details');
      });
    });

    it('configures count badges correctly', () => {
      createComponent();

      const badges = wrapper.findAllComponents(GlBadge);
      expect(badges).toHaveLength(4);

      badges.wrappers.forEach((badge) => {
        expect(badge.props('variant')).toBe('warning');
      });
    });

    it('configures icons correctly for different states', () => {
      // Test with mixed data to verify both icon types
      const mixedResults = {
        missing_indexes: [{ table_name: 'users' }], // Has issues - warning icon
        missing_tables: [], // No issues - success icon
        missing_foreign_keys: [], // No issues - success icon
        missing_sequences: [{ sequence_name: 'test_seq' }], // Has issues - warning icon
      };

      createComponent({ props: { databaseResults: mixedResults } });

      // Warning icons for sections with issues
      const warningIcons = wrapper
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'warning');
      expect(warningIcons).toHaveLength(2); // indexes and sequences

      // Success icons for sections without issues
      const successIcons = wrapper
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'check-circle-filled');
      expect(successIcons).toHaveLength(2); // tables and foreign_keys

      // Chevron icons in toggle buttons (only for sections with issues)
      const chevronIcons = wrapper
        .findAllComponents(GlIcon)
        .wrappers.filter((icon) => icon.props('name') === 'chevron-down');
      expect(chevronIcons).toHaveLength(2); // Only sections with issues have toggle buttons

      chevronIcons.forEach((icon) => {
        expect(icon.props('size')).toBe(14);
      });
    });
  });

  describe('resilience and error handling', () => {
    it('handles arrays of mixed string and object types', () => {
      const mixedResults = {
        missing_indexes: [
          'string_index_name',
          { table_name: 'users', column_name: 'email', index_name: 'complex_index' },
        ],
        missing_tables: [],
        missing_foreign_keys: [],
        missing_sequences: [],
      };

      expect(() => {
        createComponent({ props: { databaseResults: mixedResults } });
      }).not.toThrow();

      expect(findIndexesCount().text()).toBe('2');
    });

    it('renders component structure consistently', () => {
      createComponent();

      // Should always render the same number of section headers
      const sectionHeaders = wrapper.findAll('.gl-flex.gl-items-center.gl-justify-between');
      expect(sectionHeaders).toHaveLength(4); // indexes, tables, foreignKeys, sequences
    });

    it('maintains component contract with different prop combinations', () => {
      // Test various realistic data combinations
      const testCases = [
        {},
        { missing_indexes: [] },
        { missing_indexes: ['test'] },
        {
          missing_indexes: [],
          missing_tables: [],
          missing_foreign_keys: [],
          missing_sequences: [],
        },
      ];

      testCases.forEach((databaseResults) => {
        expect(() => {
          createComponent({ props: { databaseResults } });
        }).not.toThrow();

        // Should always render section labels
        expect(wrapper.text()).toContain('Indexes');
        expect(wrapper.text()).toContain('Tables');
      });
    });
  });

  describe('user experience states', () => {
    it('provides clear feedback when no issues exist', () => {
      createComponent({
        props: {
          databaseResults: noSchemaIssuesResults.schema_check_results.main,
        },
      });

      expect(findNoIssuesAlert().props('variant')).toBe('success');
      expect(wrapper.text()).toContain('No schema issues detected');
    });

    it('provides clear feedback when issues exist', () => {
      createComponent();

      // Should show issue counts and action buttons
      expect(findIndexesCount().exists()).toBe(true);
      expect(findIndexesToggle().exists()).toBe(true);
      expect(findIndexesToggle().text()).toContain('Details');
    });

    it('shows appropriate visual hierarchy', () => {
      createComponent();

      // Each section should have consistent structure
      const allSections = wrapper.findAll('.gl-mb-4');
      expect(allSections).toHaveLength(4);

      // Should have proper component counts
      expect(wrapper.findAllComponents(GlIcon).length).toBeGreaterThan(0);
      expect(wrapper.findAllComponents(GlBadge)).toHaveLength(4);
      expect(wrapper.findAllComponents(GlButton)).toHaveLength(4);
    });
  });

  describe('component rendering integrity', () => {
    it('renders all expected section types regardless of data', () => {
      const testData = [
        schemaIssuesResults.schema_check_results.main,
        noSchemaIssuesResults.schema_check_results.main,
        {},
      ];

      testData.forEach((databaseResults) => {
        createComponent({ props: { databaseResults } });

        // Should always render these section labels
        expect(wrapper.text()).toContain('Indexes');
        expect(wrapper.text()).toContain('Tables');
        expect(wrapper.text()).toContain('Foreign keys');
        expect(wrapper.text()).toContain('Sequences');
      });
    });

    it('maintains component stability across prop changes', () => {
      // Component should not crash with various prop combinations
      createComponent();
      expect(wrapper.exists()).toBe(true);

      createComponent({ props: { databaseResults: {} } });
      expect(wrapper.exists()).toBe(true);

      createComponent({
        props: {
          databaseResults: noSchemaIssuesResults.schema_check_results.main,
        },
      });
      expect(wrapper.exists()).toBe(true);
    });
  });
});
