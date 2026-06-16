import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DbInformationCard from '~/admin/database_diagnostics/components/db_information_card.vue';
import DbSchemasSection from '~/admin/database_diagnostics/components/db_schemas_section.vue';
import { databaseInformationResults, databaseInformationWithDatabaseError } from '../mock_data';

describe('DbInformationCard component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSchemasSection = () => wrapper.findComponent(DbSchemasSection);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DbInformationCard, {
      propsData: {
        dbName: 'main',
        payload: databaseInformationResults.databases.main,
        ...props,
      },
    });
  };

  describe('when the payload has no error', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the schemas section with the payload values', () => {
      const payload = databaseInformationResults.databases.main;

      expect(findSchemasSection().props()).toMatchObject({
        currentUser: payload.current_user,
        searchPath: payload.search_path,
        schemas: payload.schemas,
      });
    });

    it('does not render an error alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when the payload has an error', () => {
    beforeEach(() => {
      createComponent({ props: { payload: databaseInformationWithDatabaseError.databases.main } });
    });

    it('renders a warning alert with the error message', () => {
      expect(findAlert().props('variant')).toBe('warning');
      expect(findAlert().text()).toBe('connection refused');
    });

    it('does not render the schemas section', () => {
      expect(findSchemasSection().exists()).toBe(false);
    });
  });
});
