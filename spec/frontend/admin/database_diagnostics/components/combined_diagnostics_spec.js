import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CombinedDiagnostics from '~/admin/database_diagnostics/components/combined_diagnostics.vue';
import CollationCheckerApp from '~/admin/database_diagnostics/components/collation_checker_app.vue';
import DatabaseInformationApp from '~/admin/database_diagnostics/components/database_information_app.vue';
import SchemaCheckerApp from '~/admin/database_diagnostics/components/schema_checker_app.vue';

describe('CombinedDiagnostics component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(CombinedDiagnostics);
  };

  const findDatabaseInformation = () => wrapper.findComponent(DatabaseInformationApp);
  const findCollationChecker = () => wrapper.findComponent(CollationCheckerApp);
  const findSchemaChecker = () => wrapper.findComponent(SchemaCheckerApp);

  beforeEach(() => {
    createComponent();
  });

  it('renders all three diagnostic components', () => {
    expect(findDatabaseInformation().exists()).toBe(true);
    expect(findCollationChecker().exists()).toBe(true);
    expect(findSchemaChecker().exists()).toBe(true);
  });

  it('renders DatabaseInformation above the checkers', () => {
    const sections = wrapper.findAll('section > section');

    // First section is the database information panel, then the two checkers.
    expect(sections.at(0).findComponent(DatabaseInformationApp).exists()).toBe(true);
    expect(sections.at(1).findComponent(CollationCheckerApp).exists()).toBe(true);
    expect(sections.at(2).findComponent(SchemaCheckerApp).exists()).toBe(true);
  });
});
