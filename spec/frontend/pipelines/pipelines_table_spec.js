import { GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelinesTable from '~/pipelines/components/pipelines_list/pipelines_table.vue';

describe('Pipelines Table', () => {
  let pipeline;
  let wrapper;

  const jsonFixtureName = 'pipelines/pipelines.json';

  const defaultProps = {
    pipelines: [],
    viewType: 'root',
  };

  const createComponent = (props = defaultProps, flagState = false) => {
    wrapper = extendedWrapper(
      mount(PipelinesTable, {
        propsData: props,
        provide: {
          glFeatures: {
            newPipelinesTable: flagState,
          },
        },
      }),
    );
  };

  const findRows = () => wrapper.findAll('.commit.gl-responsive-table-row');
  const findGlTable = () => wrapper.findComponent(GlTable);
  const findLegacyTable = () => wrapper.findByTestId('ci-table');

  preloadFixtures(jsonFixtureName);

  beforeEach(() => {
    const { pipelines } = getJSONFixture(jsonFixtureName);
    pipeline = pipelines.find((p) => p.user !== null && p.commit !== null);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('table with feature flag off', () => {
    describe('renders the table correctly', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should render a table', () => {
        expect(wrapper.classes()).toContain('ci-table');
      });

      it('should render table head with correct columns', () => {
        expect(wrapper.find('.table-section.js-pipeline-status').text()).toEqual('Status');

        expect(wrapper.find('.table-section.js-pipeline-info').text()).toEqual('Pipeline');

        expect(wrapper.find('.table-section.js-pipeline-commit').text()).toEqual('Commit');

        expect(wrapper.find('.table-section.js-pipeline-stages').text()).toEqual('Stages');
      });
    });

    describe('without data', () => {
      it('should render an empty table', () => {
        createComponent();

        expect(findRows()).toHaveLength(0);
      });
    });

    describe('with data', () => {
      it('should render rows', () => {
        createComponent({ pipelines: [pipeline], viewType: 'root' });

        expect(findRows()).toHaveLength(1);
      });
    });
  });

  describe('table with feature flag on', () => {
    it('displays new table', () => {
      createComponent(defaultProps, true);

      expect(findGlTable().exists()).toBe(true);
      expect(findLegacyTable().exists()).toBe(false);
    });
  });
});
