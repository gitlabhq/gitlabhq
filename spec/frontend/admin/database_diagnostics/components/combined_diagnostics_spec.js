import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CombinedDiagnostics from '~/admin/database_diagnostics/components/combined_diagnostics.vue';
import VacuumInformationApp from '~/admin/database_diagnostics/components/vacuum_information_app.vue';
import CollationCheckerApp from '~/admin/database_diagnostics/components/collation_checker_app.vue';
import DatabaseInformationApp from '~/admin/database_diagnostics/components/database_information_app.vue';
import SchemaCheckerApp from '~/admin/database_diagnostics/components/schema_checker_app.vue';

describe('CombinedDiagnostics component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(CombinedDiagnostics);
  };

  const findDatabaseInformation = () => wrapper.findComponent(DatabaseInformationApp);
  const findVacuumInformation = () => wrapper.findComponent(VacuumInformationApp);
  const findCollationChecker = () => wrapper.findComponent(CollationCheckerApp);
  const findSchemaChecker = () => wrapper.findComponent(SchemaCheckerApp);

  beforeEach(() => {
    createComponent();
  });

  it('renders all diagnostic components', () => {
    expect(findDatabaseInformation().exists()).toBe(true);
    expect(findVacuumInformation().exists()).toBe(true);
    expect(findCollationChecker().exists()).toBe(true);
    expect(findSchemaChecker().exists()).toBe(true);
  });

  it('renders the sections in order: database info, vacuum, then the checkers', () => {
    const allElements = wrapper.findAll('*').wrappers.map((element) => element.element);
    const positions = [
      DatabaseInformationApp,
      VacuumInformationApp,
      CollationCheckerApp,
      SchemaCheckerApp,
    ].map((component) => allElements.indexOf(wrapper.findComponent(component).element));

    expect(positions).toEqual([...positions].sort((a, b) => a - b));
  });
});
