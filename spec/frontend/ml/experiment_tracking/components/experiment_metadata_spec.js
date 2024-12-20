import { GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ExperimentMetadata from '~/ml/experiment_tracking/components/experiment_metadata.vue';
import { MOCK_EXPERIMENT, MOCK_EXPERIMENT_METADATA } from '../routes/experiments/show/mock_data';

describe('MlExperimentsShow', () => {
  let wrapper;

  const createWrapper = (experiment = MOCK_EXPERIMENT) => {
    wrapper = mountExtended(ExperimentMetadata, {
      propsData: { experiment },
      stubs: { GlTableLite },
    });
  };

  const createWrapperWithExperimentMetadata = () => {
    createWrapper({ ...MOCK_EXPERIMENT, metadata: MOCK_EXPERIMENT_METADATA });
  };

  const findMetadataTableRow = (idx) =>
    wrapper.findComponent(GlTableLite).find('tbody').findAll('tr').at(idx);
  const findMetadataTableColumn = (row, col) => findMetadataTableRow(row).findAll('td').at(col);
  const findMetadataHeader = () => wrapper.findByTestId('metadata-header');
  const findMetadataEmptyState = () => wrapper.findByTestId('metadata-empty-state');

  describe('Experiments metadata', () => {
    it('has correct header', () => {
      createWrapper();

      expect(findMetadataHeader().text()).toBe('Experiment metadata');
    });

    it('shows empty state if there is no metadata', () => {
      createWrapper();

      expect(findMetadataEmptyState().text()).toBe('No logged experiment metadata');
    });

    it('shows the metadata', () => {
      createWrapperWithExperimentMetadata();

      MOCK_EXPERIMENT_METADATA.forEach((metadata, idx) => {
        expect(findMetadataTableColumn(idx, 0).text()).toContain(metadata.name);
        expect(findMetadataTableColumn(idx, 1).text()).toContain(metadata.value);
      });
    });
  });
});
