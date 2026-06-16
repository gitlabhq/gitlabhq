import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DatabaseInformationApp from '~/admin/database_diagnostics/components/database_information_app.vue';
import DbInformationCard from '~/admin/database_diagnostics/components/db_information_card.vue';
import { databaseInformationResults } from '../mock_data';

describe('DatabaseInformationApp component', () => {
  let wrapper;

  const findTitle = () => wrapper.findByTestId('title');
  const findCards = () => wrapper.findAllComponents(DbInformationCard);

  const createComponent = ({ databaseInformation = databaseInformationResults } = {}) => {
    wrapper = shallowMountExtended(DatabaseInformationApp, {
      provide: { databaseInformation },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the section title', () => {
    expect(findTitle().text()).toBe('Database information');
  });

  it('renders one card per database', () => {
    expect(findCards()).toHaveLength(Object.keys(databaseInformationResults.databases).length);
  });

  it('passes the database name and payload to each card', () => {
    const card = findCards().at(0);

    expect(card.props()).toMatchObject({
      dbName: 'main',
      payload: databaseInformationResults.databases.main,
    });
  });
});
