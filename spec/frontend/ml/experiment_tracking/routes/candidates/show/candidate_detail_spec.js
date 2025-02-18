import { GlAvatarLabeled, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CandidateDetail from '~/ml/experiment_tracking/routes/candidates/show/candidate_detail.vue';
import { newCandidate } from 'jest/ml/model_registry/mock_data';

describe('ml/experiment_tracking/routes/candidates/show/candidate_detail.vue', () => {
  let wrapper;

  const defaultProps = {
    candidate: newCandidate(),
  };

  const createWrapper = (props = {}) => {
    return mountExtended(CandidateDetail, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findArtifactsTab = () => wrapper.findByTestId('artifacts');
  const findAllTabs = () => wrapper.findAll('.gl-tab-nav-item');
  const findMetricsTab = () => wrapper.findByTestId('metrics');
  const findMlflowIdButton = () => wrapper.findComponent(GlButton);
  const findMetricsTable = () => wrapper.findByTestId('metrics-table');
  const findMetadata = () => wrapper.findByTestId('metadata');
  const findMlflowRunId = () => wrapper.findByTestId('mlflow-run-id');
  const findCiJobPathLink = () => wrapper.findByTestId('ci-job-path');
  const findArtifactLink = () => wrapper.findByTestId('artifacts-link');
  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findParametersSection = () => wrapper.findByTestId('parameters');
  const findParametersTable = () => wrapper.findByTestId('parameters-table');
  const findCiSection = () => wrapper.findByTestId('ci');

  describe('Basic rendering', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders all three tabs', () => {
      const tabs = findAllTabs();
      expect(tabs.at(0).text()).toBe('Details & Metadata');
      expect(tabs.at(1).text()).toBe('Artifacts');
      expect(tabs.at(2).text()).toBe('Performance');
    });

    it('displays MLflow run ID', () => {
      expect(findMlflowRunId().text()).toBe('abcdefg');
    });

    it('renders metadata section', () => {
      expect(findMetadata().text()).toContain('FileName');
      expect(findMetadata().text()).toContain('test.py');
    });
  });

  describe('Parameters section', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders parameters table when parameters exist', () => {
      expect(findParametersSection().text()).toContain('Parameters');
    });

    it('renders metrics table with correct columns', () => {
      const fields = findParametersTable().props('fields');
      expect(fields.map((e) => e.label)).toEqual(['Name', 'Value']);
    });

    it('formats metrics data correctly', () => {
      expect(findParametersTable().vm.$attrs.items).toEqual([
        { name: 'Algorithm', value: 'Decision Tree' },
        { name: 'MaxDepth', value: '3' },
      ]);
    });

    it('shows no parameters message when parameters are empty', () => {
      wrapper = createWrapper({
        candidate: {
          ...defaultProps.candidate,
          params: [],
        },
      });
      expect(findParametersSection().text()).toContain('No logged parameters');
    });
  });

  describe('CI information section', () => {
    it('renders CI job information when available', () => {
      wrapper = createWrapper();
      expect(findCiJobPathLink().text()).toContain('test');
    });

    it('renders user information when available', () => {
      wrapper = createWrapper();
      expect(findAvatarLabeled().text()).toContain('CI User');
    });

    it('shows no CI message when CI information is missing', () => {
      wrapper = createWrapper({
        candidate: {
          ...defaultProps.candidate,
          info: { ...defaultProps.candidate.info, ciJob: null },
        },
      });
      expect(findCiSection().text()).toContain('Run not linked to a CI build');
    });
  });

  describe('Metrics table', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders metrics table with correct columns', () => {
      const fields = findMetricsTable().props('fields');
      expect(fields.map((e) => e.label)).toEqual([
        'Metric',
        'Step 0',
        'Step 1',
        'Step 2',
        'Step 3',
      ]);
    });

    it('formats metrics data correctly', () => {
      expect(findMetricsTable().vm.$attrs.items).toContainEqual({
        name: 'Accuracy',
        1: '.99',
        2: '.98',
        3: '.97',
      });
    });

    it('shows no metrics message when metrics are empty', () => {
      wrapper = createWrapper({
        candidate: {
          ...defaultProps.candidate,
          metrics: [],
        },
      });
      expect(findMetricsTab().text()).toContain('No logged metrics');
    });

    it('handles null steps', () => {
      wrapper = createWrapper({
        candidate: {
          ...defaultProps.candidate,
          metrics: [{ name: 'AUC', value: '.55', step: undefined }],
        },
      });
      expect(findMetricsTab().text()).toContain('Step 0AUC');
    });
  });

  describe('MLflow ID copy button', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('copies MLflow ID to clipboard when clicked', async () => {
      jest.spyOn(navigator.clipboard, 'writeText').mockImplementation(() => Promise.resolve());
      await findMlflowIdButton().vm.$emit('click');
      expect(navigator.clipboard.writeText).toHaveBeenCalledWith('abcdefg');
      jest.restoreAllMocks();
    });
  });

  describe('Artifacts tab', () => {
    it('renders artifact link when available', () => {
      wrapper = createWrapper();
      expect(findArtifactLink().attributes('href')).toBe('path_to_artifact');
    });

    it('shows no artifacts message when artifact path is missing', () => {
      wrapper = createWrapper({
        candidate: {
          ...defaultProps.candidate,
          info: { ...defaultProps.candidate.info, pathToArtifact: null },
        },
      });
      expect(findArtifactsTab().text()).toContain('No logged artifacts');
    });
  });
});
