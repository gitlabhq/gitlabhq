import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CombinedDiagnostics from '~/admin/database_diagnostics/components/combined_diagnostics.vue';
import CollationCheckerApp from '~/admin/database_diagnostics/components/collation_checker_app.vue';
import SchemaCheckerApp from '~/admin/database_diagnostics/components/schema_checker_app.vue';

describe('CombinedDiagnostics component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(CombinedDiagnostics);
  };

  const findCollationChecker = () => wrapper.findComponent(CollationCheckerApp);
  const findSchemaChecker = () => wrapper.findComponent(SchemaCheckerApp);

  beforeEach(() => {
    createComponent();
  });

  it('renders both diagnostic components', () => {
    expect(findCollationChecker().exists()).toBe(true);
    expect(findSchemaChecker().exists()).toBe(true);
  });
});
