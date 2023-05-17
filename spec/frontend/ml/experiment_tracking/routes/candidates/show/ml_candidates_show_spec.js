import { shallowMount } from '@vue/test-utils';
import MlCandidatesShow from '~/ml/experiment_tracking/routes/candidates/show';
import DetailRow from '~/ml/experiment_tracking/routes/candidates/show/components/candidate_detail_row.vue';
import { TITLE_LABEL } from '~/ml/experiment_tracking/routes/candidates/show/translations';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import { newCandidate } from './mock_data';

describe('MlCandidatesShow', () => {
  let wrapper;
  const CANDIDATE = newCandidate();

  const createWrapper = (createCandidate = () => CANDIDATE) => {
    wrapper = shallowMount(MlCandidatesShow, {
      propsData: { candidate: createCandidate() },
    });
  };

  const findDeleteButton = () => wrapper.findComponent(DeleteButton);
  const findHeader = () => wrapper.findComponent(ModelExperimentsHeader);
  const findNthDetailRow = (index) => wrapper.findAllComponents(DetailRow).at(index);
  const findSectionLabel = (label) => wrapper.find(`[sectionLabel='${label}']`);
  const findLabel = (label) => wrapper.find(`[label='${label}']`);

  describe('Header', () => {
    beforeEach(() => createWrapper());

    it('shows delete button', () => {
      expect(findDeleteButton().exists()).toBe(true);
    });

    it('passes the delete path to delete button', () => {
      expect(findDeleteButton().props('deletePath')).toBe('path_to_candidate');
    });

    it('passes the right title', () => {
      expect(findHeader().props('pageTitle')).toBe(TITLE_LABEL);
    });
  });

  describe('Detail Table', () => {
    describe('All info available', () => {
      beforeEach(() => createWrapper());

      const expectedTable = [
        ['Info', 'ID', CANDIDATE.info.iid, ''],
        ['', 'MLflow run ID', CANDIDATE.info.eid, ''],
        ['', 'Status', CANDIDATE.info.status, ''],
        ['', 'Experiment', CANDIDATE.info.experiment_name, CANDIDATE.info.path_to_experiment],
        ['', 'Artifacts', 'Artifacts', CANDIDATE.info.path_to_artifact],
        ['Parameters', CANDIDATE.params[0].name, CANDIDATE.params[0].value, ''],
        ['', CANDIDATE.params[1].name, CANDIDATE.params[1].value, ''],
        ['Metrics', CANDIDATE.metrics[0].name, CANDIDATE.metrics[0].value, ''],
        ['', CANDIDATE.metrics[1].name, CANDIDATE.metrics[1].value, ''],
        ['Metadata', CANDIDATE.metadata[0].name, CANDIDATE.metadata[0].value, ''],
        ['', CANDIDATE.metadata[1].name, CANDIDATE.metadata[1].value, ''],
      ].map((row, index) => [index, ...row]);

      it.each(expectedTable)(
        'row %s is created correctly',
        (index, sectionLabel, label, text, href) => {
          const row = findNthDetailRow(index);

          expect(row.props()).toMatchObject({ sectionLabel, label, text, href });
        },
      );
      it('does not render params', () => {
        expect(findSectionLabel('Parameters').exists()).toBe(true);
      });

      it('renders all conditional rows', () => {
        // This is a bit of a duplicated test from the above table test, but having this makes sure that the
        // tests that test the negatives are implemented correctly
        expect(findLabel('Artifacts').exists()).toBe(true);
        expect(findSectionLabel('Parameters').exists()).toBe(true);
        expect(findSectionLabel('Metadata').exists()).toBe(true);
        expect(findSectionLabel('Metrics').exists()).toBe(true);
      });
    });

    describe('No artifact path', () => {
      beforeEach(() =>
        createWrapper(() => {
          const candidate = newCandidate();
          delete candidate.info.path_to_artifact;
          return candidate;
        }),
      );

      it('does not render artifact row', () => {
        expect(findLabel('Artifacts').exists()).toBe(false);
      });
    });

    describe('No params, metrics, ci or metadata available', () => {
      beforeEach(() =>
        createWrapper(() => {
          const candidate = newCandidate();
          delete candidate.params;
          delete candidate.metrics;
          delete candidate.metadata;
          return candidate;
        }),
      );

      it('does not render params', () => {
        expect(findSectionLabel('Parameters').exists()).toBe(false);
      });

      it('does not render metadata', () => {
        expect(findSectionLabel('Metadata').exists()).toBe(false);
      });

      it('does not render metrics', () => {
        expect(findSectionLabel('Metrics').exists()).toBe(false);
      });
    });
  });
});
