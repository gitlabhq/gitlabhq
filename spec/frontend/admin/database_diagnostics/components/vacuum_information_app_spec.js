import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VacuumInformationApp from '~/admin/database_diagnostics/components/vacuum_information_app.vue';
import DbVacuumSection from '~/admin/database_diagnostics/components/db_vacuum_section.vue';
import { databaseInformationResults, vacuumActivity } from '../mock_data';

describe('VacuumInformationApp component', () => {
  let wrapper;

  const findTitle = () => wrapper.find('h2');
  const findSections = () => wrapper.findAllComponents(DbVacuumSection);

  const createComponent = ({ databaseInformation = databaseInformationResults } = {}) => {
    wrapper = shallowMountExtended(VacuumInformationApp, {
      provide: { databaseInformation },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the section title', () => {
    expect(findTitle().text()).toBe('Vacuum information');
  });

  it('renders one vacuum section per database', () => {
    expect(findSections()).toHaveLength(Object.keys(databaseInformationResults.databases).length);
  });

  it('passes the vacuum activity to each section', () => {
    expect(findSections().at(0).props('vacuums')).toEqual(vacuumActivity);
  });

  it('passes activityAvailable through to each section', () => {
    expect(findSections().at(0).props('activityAvailable')).toBe(true);
  });

  it('marks activity unavailable when the payload flag is false', () => {
    createComponent({
      databaseInformation: {
        databases: { main: { vacuums: [], vacuum_activity_available: false } },
      },
    });

    expect(findSections().at(0).props('activityAvailable')).toBe(false);
  });

  it('defaults activityAvailable to true when the flag is absent', () => {
    createComponent({ databaseInformation: { databases: { main: {} } } });

    expect(findSections().at(0).props('activityAvailable')).toBe(true);
  });

  it('falls back to an empty array when a database has no vacuum data', () => {
    createComponent({ databaseInformation: { databases: { main: {} } } });

    expect(findSections().at(0).props('vacuums')).toEqual([]);
  });
});
