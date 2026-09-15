import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AutovacuumConfigApp from '~/admin/database_diagnostics/components/autovacuum_config_app.vue';
import AutovacuumConfigSection from '~/admin/database_diagnostics/components/autovacuum_config_section.vue';
import { databaseInformationResults, autovacuumConfig } from '../mock_data';

describe('AutovacuumConfigApp component', () => {
  let wrapper;

  const findTitle = () => wrapper.find('h2');
  const findSections = () => wrapper.findAllComponents(AutovacuumConfigSection);

  const createComponent = ({ databaseInformation = databaseInformationResults } = {}) => {
    wrapper = shallowMountExtended(AutovacuumConfigApp, {
      provide: { databaseInformation },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the section title', () => {
    expect(findTitle().text()).toBe('Autovacuum configuration');
  });

  it('renders one config section per database', () => {
    expect(findSections()).toHaveLength(Object.keys(databaseInformationResults.databases).length);
  });

  it('passes the autovacuum config to each section', () => {
    expect(findSections().at(0).props('config')).toEqual(autovacuumConfig);
  });

  it('falls back to an empty object when a database has no autovacuum config', () => {
    createComponent({ databaseInformation: { databases: { main: {} } } });

    expect(findSections().at(0).props('config')).toEqual({});
  });
});
