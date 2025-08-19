import { GlCard, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SchemaResultsContainer from '~/admin/database_diagnostics/components/schema_results_container.vue';
import SchemaIssuesSection from '~/admin/database_diagnostics/components/schema_issues_section.vue';
import {
  schemaIssuesResults,
  multiDatabaseResults,
  singleDatabaseResults,
  noSchemaIssuesResults,
} from '../mock_data';

describe('SchemaResultsContainer component', () => {
  let wrapper;

  const defaultProps = {
    schemaDiagnostics: schemaIssuesResults,
  };

  const findDatabaseSections = () => wrapper.findAll('[data-testid^="database-"]');
  const findSchemaIssuesSections = () => wrapper.findAllComponents(SchemaIssuesSection);
  const findCards = () => wrapper.findAllComponents(GlCard);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(SchemaResultsContainer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GlCard, GlSprintf },
    });
  };

  describe('with multiple databases', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders database sections with correct titles', () => {
      const sections = findDatabaseSections();
      expect(sections).toHaveLength(2);
      expect(sections.at(0).text()).toMatchInterpolatedText('Database: main');
      expect(sections.at(1).text()).toMatchInterpolatedText('Database: ci');
    });

    it('renders SchemaIssuesSection for each database', () => {
      const issuesSections = findSchemaIssuesSections();
      expect(issuesSections).toHaveLength(2);
    });

    it('passes correct database results to each SchemaIssuesSection', () => {
      const issuesSections = findSchemaIssuesSections();

      expect(issuesSections.at(0).props('databaseResults')).toEqual(
        schemaIssuesResults.schema_check_results.main,
      );
      expect(issuesSections.at(1).props('databaseResults')).toEqual(
        schemaIssuesResults.schema_check_results.ci,
      );
    });

    it('wraps each database in a card', () => {
      const cards = findCards();
      expect(cards).toHaveLength(2);
    });
  });

  describe('with single database', () => {
    beforeEach(() => {
      createComponent({ props: { schemaDiagnostics: singleDatabaseResults } });
    });

    it('renders single database section', () => {
      const sections = findDatabaseSections();
      expect(sections).toHaveLength(1);
      expect(sections.at(0).text()).toMatchInterpolatedText('Database: main');
    });

    it('displays single database name', () => {
      const text = wrapper.text().replace(/\s+/g, ' '); // Normalize whitespace
      expect(text).toContain('Database: main');
      expect(text).not.toContain('Database: ci');
    });

    it('renders single SchemaIssuesSection', () => {
      const issuesSections = findSchemaIssuesSections();
      expect(issuesSections).toHaveLength(1);

      expect(issuesSections.at(0).props('databaseResults')).toEqual(
        singleDatabaseResults.schema_check_results.main,
      );
    });
  });

  describe('with many databases', () => {
    beforeEach(() => {
      createComponent({ props: { schemaDiagnostics: multiDatabaseResults } });
    });

    it('renders all database sections', () => {
      const sections = findDatabaseSections();
      expect(sections).toHaveLength(3);

      expect(sections.at(0).text()).toMatchInterpolatedText('Database: main');
      expect(sections.at(1).text()).toMatchInterpolatedText('Database: ci');
      expect(sections.at(2).text()).toMatchInterpolatedText('Database: registry');
    });

    it('renders SchemaIssuesSection for all databases', () => {
      const issuesSections = findSchemaIssuesSections();
      expect(issuesSections).toHaveLength(3);

      expect(issuesSections.at(0).props('databaseResults')).toEqual(
        multiDatabaseResults.schema_check_results.main,
      );
      expect(issuesSections.at(1).props('databaseResults')).toEqual(
        multiDatabaseResults.schema_check_results.ci,
      );
      expect(issuesSections.at(2).props('databaseResults')).toEqual(
        multiDatabaseResults.schema_check_results.registry,
      );
    });
  });

  describe('with no issues', () => {
    beforeEach(() => {
      createComponent({ props: { schemaDiagnostics: noSchemaIssuesResults } });
    });

    it('renders database section even with no issues', () => {
      const sections = findDatabaseSections();
      expect(sections).toHaveLength(1);
    });

    it('passes empty results to SchemaIssuesSection', () => {
      const issuesSection = findSchemaIssuesSections().at(0);
      const passedResults = issuesSection.props('databaseResults');

      expect(passedResults.missing_indexes).toEqual([]);
      expect(passedResults.missing_tables).toEqual([]);
      expect(passedResults.missing_foreign_keys).toEqual([]);
      expect(passedResults.missing_sequences).toEqual([]);
    });
  });

  describe('edge cases', () => {
    it('handles empty schema_check_results gracefully', () => {
      const emptyResults = {
        metadata: { last_run_at: '2025-07-23T10:00:00Z' },
        schema_check_results: {},
      };

      createComponent({ props: { schemaDiagnostics: emptyResults } });

      expect(findDatabaseSections()).toHaveLength(0);
      expect(findSchemaIssuesSections()).toHaveLength(0);
      expect(findCards()).toHaveLength(0);
    });

    it('handles database names with special characters', () => {
      const specialResults = {
        metadata: { last_run_at: '2025-07-23T10:00:00Z' },
        schema_check_results: {
          'database-with-dashes': {
            missing_indexes: [],
            missing_tables: [],
            missing_foreign_keys: [],
            missing_sequences: [],
          },
        },
      };

      createComponent({ props: { schemaDiagnostics: specialResults } });

      const sections = findDatabaseSections();
      expect(sections.at(0).text()).toMatchInterpolatedText('Database: database-with-dashes');
    });
  });
});
