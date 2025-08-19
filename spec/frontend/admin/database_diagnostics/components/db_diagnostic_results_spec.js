import { GlCard, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DbDiagnosticResults from '~/admin/database_diagnostics/components/db_diagnostic_results.vue';
import DbCollationMismatches from '~/admin/database_diagnostics/components/db_collation_mismatches.vue';
import DbCorruptedIndexes from '~/admin/database_diagnostics/components/db_corrupted_indexes.vue';
import { collationMismatchResults } from '../mock_data';

describe('DbDiagnosticResults component', () => {
  let wrapper;
  const defaultProps = {
    dbName: 'main',
    dbDiagnosticResult: collationMismatchResults.databases.main,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DbDiagnosticResults, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GlCard, GlSprintf },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('passes correct props to DbCollationMismatches', () => {
    expect(wrapper.findComponent(DbCollationMismatches).props('collationMismatches')).toBe(
      defaultProps.dbDiagnosticResult.collation_mismatches,
    );
  });

  it('passes correct props to DbCorruptedIndexes', () => {
    expect(wrapper.findComponent(DbCorruptedIndexes).props('corruptedIndexes')).toBe(
      defaultProps.dbDiagnosticResult.corrupted_indexes,
    );
  });

  it('displays the database name in the header', () => {
    expect(wrapper.text()).toMatchInterpolatedText(`Database: ${defaultProps.dbName}`);
  });
});
