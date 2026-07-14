import { GlBadge, GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DbSchemasSection from '~/admin/database_diagnostics/components/db_schemas_section.vue';
import { databaseInformationResults } from '../mock_data';

describe('DbSchemasSection component', () => {
  let wrapper;

  const { schemas } = databaseInformationResults.databases.main;

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findBadges = () => wrapper.findAllComponents(GlBadge);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(DbSchemasSection, {
      propsData: {
        schemas,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders a table of schemas', () => {
    expect(findTable().exists()).toBe(true);
    expect(findTable().props('items')).toEqual(schemas);
  });

  it('renders a Current badge for the current schema only', () => {
    const currentSchemas = schemas.filter((schema) => schema.current);

    expect(findBadges()).toHaveLength(currentSchemas.length);
    expect(findBadges().at(0).text()).toBe('Current');
  });
});
