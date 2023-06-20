import { shallowMount } from '@vue/test-utils';
import { GlAvatarLabeled, GlLink } from '@gitlab/ui';
import MlCandidatesShow from '~/ml/experiment_tracking/routes/candidates/show';
import DetailRow from '~/ml/experiment_tracking/routes/candidates/show/components/candidate_detail_row.vue';
import { TITLE_LABEL } from '~/ml/experiment_tracking/routes/candidates/show/translations';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import { newCandidate } from './mock_data';

describe('MlCandidatesShow', () => {
  let wrapper;
  const CANDIDATE = newCandidate();
  const USER_ROW = 6;

  const createWrapper = (createCandidate = () => CANDIDATE) => {
    wrapper = shallowMount(MlCandidatesShow, {
      propsData: { candidate: createCandidate() },
    });
  };

  const findDeleteButton = () => wrapper.findComponent(DeleteButton);
  const findHeader = () => wrapper.findComponent(ModelExperimentsHeader);
  const findNthDetailRow = (index) => wrapper.findAllComponents(DetailRow).at(index);
  const findLinkInNthDetailRow = (index) => findNthDetailRow(index).findComponent(GlLink);
  const findSectionLabel = (label) => wrapper.find(`[sectionLabel='${label}']`);
  const findLabel = (label) => wrapper.find(`[label='${label}']`);
  const findCiUserDetailRow = () => findNthDetailRow(USER_ROW);
  const findCiUserAvatar = () => findCiUserDetailRow().findComponent(GlAvatarLabeled);
  const findCiUserAvatarNameLink = () => findCiUserAvatar().findComponent(GlLink);

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

      const mrText = `!${CANDIDATE.info.ci_job.merge_request.iid} ${CANDIDATE.info.ci_job.merge_request.title}`;
      const expectedTable = [
        ['Info', 'ID', CANDIDATE.info.iid],
        ['', 'MLflow run ID', CANDIDATE.info.eid],
        ['', 'Status', CANDIDATE.info.status],
        ['', 'Experiment', CANDIDATE.info.experiment_name],
        ['', 'Artifacts', 'Artifacts'],
        ['CI', 'Job', CANDIDATE.info.ci_job.name],
        ['', 'Triggered by', 'CI User'],
        ['', 'Merge request', mrText],
        ['Parameters', CANDIDATE.params[0].name, CANDIDATE.params[0].value],
        ['', CANDIDATE.params[1].name, CANDIDATE.params[1].value],
        ['Metrics', CANDIDATE.metrics[0].name, CANDIDATE.metrics[0].value],
        ['', CANDIDATE.metrics[1].name, CANDIDATE.metrics[1].value],
        ['Metadata', CANDIDATE.metadata[0].name, CANDIDATE.metadata[0].value],
        ['', CANDIDATE.metadata[1].name, CANDIDATE.metadata[1].value],
      ].map((row, index) => [index, ...row]);

      it.each(expectedTable)(
        'row %s is created correctly',
        (rowIndex, sectionLabel, label, text) => {
          const row = findNthDetailRow(rowIndex);

          expect(row.props()).toMatchObject({ sectionLabel, label });
          expect(row.text()).toBe(text);
        },
      );

      describe('Table links', () => {
        const linkRows = [
          [3, CANDIDATE.info.path_to_experiment],
          [4, CANDIDATE.info.path_to_artifact],
          [5, CANDIDATE.info.ci_job.path],
          [7, CANDIDATE.info.ci_job.merge_request.path],
        ];

        it.each(linkRows)('row %s is created correctly', (rowIndex, href) => {
          expect(findLinkInNthDetailRow(rowIndex).attributes().href).toBe(href);
        });
      });

      describe('CI triggerer', () => {
        it('renders user row', () => {
          const avatar = findCiUserAvatar();
          expect(avatar.props()).toMatchObject({
            label: '',
          });
          expect(avatar.attributes().src).toEqual('/img.png');
        });

        it('renders user name', () => {
          const nameLink = findCiUserAvatarNameLink();

          expect(nameLink.attributes().href).toEqual('path/to/ci/user');
          expect(nameLink.text()).toEqual('CI User');
        });
      });

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
        expect(findSectionLabel('CI').exists()).toBe(true);
        expect(findLabel('Merge request').exists()).toBe(true);
        expect(findLabel('Triggered by').exists()).toBe(true);
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
          delete candidate.info.ci_job;
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

      it('does not render CI info', () => {
        expect(findSectionLabel('CI').exists()).toBe(false);
      });
    });

    describe('Has CI, but no user or mr', () => {
      beforeEach(() =>
        createWrapper(() => {
          const candidate = newCandidate();
          delete candidate.info.ci_job.user;
          delete candidate.info.ci_job.merge_request;
          return candidate;
        }),
      );

      it('does not render MR info', () => {
        expect(findLabel('Merge request').exists()).toBe(false);
      });

      it('does not render CI user info', () => {
        expect(findLabel('Triggered by').exists()).toBe(false);
      });
    });
  });
});
