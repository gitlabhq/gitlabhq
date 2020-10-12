import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import PipelinesTable from '~/pipelines/components/pipelines_list/pipelines_table.vue';

describe('Pipelines Table', () => {
  let pipeline;
  let wrapper;

  const jsonFixtureName = 'pipelines/pipelines.json';

  const defaultProps = {
    pipelines: [],
    autoDevopsHelpPath: 'foo',
    viewType: 'root',
  };

  const createComponent = (props = defaultProps) => {
    wrapper = mount(PipelinesTable, {
      propsData: props,
    });
  };
  const findRows = () => wrapper.findAll('.commit.gl-responsive-table-row');
  const findGlButtons = () => wrapper.findAll(GlButton);

  preloadFixtures(jsonFixtureName);

  beforeEach(() => {
    const { pipelines } = getJSONFixture(jsonFixtureName);
    pipeline = pipelines.find(p => p.user !== null && p.commit !== null);

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('table', () => {
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
      expect(findRows()).toHaveLength(0);
    });
  });

  describe('with data', () => {
    it('should render rows', () => {
      createComponent({ pipelines: [pipeline], autoDevopsHelpPath: 'foo', viewType: 'root' });

      expect(findRows()).toHaveLength(1);
    });
  });

  describe('pipline actions', () => {
    it('should set the "Re-deploy" title', () => {
      const pipelines = [{ ...pipeline, flags: { cancelable: false, retryable: true } }];
      createComponent({ ...defaultProps, pipelines });
      expect(findGlButtons().length).toBe(1);
      expect(
        findGlButtons()
          .at(0)
          .attributes('title'),
      ).toMatch('Retry');
    });

    it('should set the "Cancel" title', () => {
      const pipelines = [{ ...pipeline, flags: { cancelable: true, retryable: false } }];
      createComponent({ ...defaultProps, pipelines });
      expect(findGlButtons().length).toBe(1);
      expect(
        findGlButtons()
          .at(0)
          .attributes('title'),
      ).toMatch('Cancel');
    });
  });
});
