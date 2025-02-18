import { GlButton, GlTabs, GlTab, GlBadge, GlSprintf, GlIcon, GlLink } from '@gitlab/ui';
import VueRouter from 'vue-router';
import Vue from 'vue';
import MlExperimentsShow from '~/ml/experiment_tracking/routes/experiments/show/ml_experiments_show.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as urlHelpers from '~/lib/utils/url_utility';
import CandidateList from '~/ml/experiment_tracking/components/candidate_list.vue';
import ExperimentMetadata from '~/ml/experiment_tracking/components/experiment_metadata.vue';
import PerformanceGraph from '~/ml/experiment_tracking/components/performance_graph.vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import waitForPromises from 'helpers/wait_for_promises';
import {
  MOCK_PAGE_INFO,
  MOCK_EXPERIMENT,
  MOCK_MODEL_EXPERIMENT,
  MOCK_CANDIDATES,
} from './mock_data';

jest.mock('~/ml/experiment_tracking/components/experiment_metadata.vue', () => {
  const { props } = jest.requireActual(
    '~/ml/experiment_tracking/components/experiment_metadata.vue',
  ).default;
  return {
    props,
    render() {},
  };
});

jest.mock('~/ml/experiment_tracking/components/candidate_list.vue', () => {
  const { props } = jest.requireActual(
    '~/ml/experiment_tracking/components/candidate_list.vue',
  ).default;
  return {
    props,
    render() {},
  };
});

jest.mock('~/ml/experiment_tracking/components/performance_graph.vue', () => {
  const { props } = jest.requireActual(
    '~/ml/experiment_tracking/components/performance_graph.vue',
  ).default;
  return {
    props,
    render() {},
  };
});

describe('MlExperimentsShow', () => {
  let wrapper;
  Vue.use(VueRouter);

  const createWrapper = ({
    candidates = MOCK_CANDIDATES,
    metricNames = ['rmse', 'auc', 'mae'],
    paramNames = ['l1_ratio'],
    pageInfo = MOCK_PAGE_INFO,
    experiment = MOCK_EXPERIMENT,
    emptyStateSvgPath = 'path',
    mountFn = shallowMountExtended,
    mlflowTrackingUrl = 'mlflow/tracking/url',
    canWriteModelExperiments = true,
  } = {}) => {
    wrapper = mountFn(MlExperimentsShow, {
      propsData: {
        experiment,
        candidates,
        metricNames,
        paramNames,
        pageInfo,
        emptyStateSvgPath,
        mlflowTrackingUrl,
        canWriteModelExperiments,
      },
      stubs: { GlTabs, GlBadge, CandidateList, GlSprintf, TimeAgoTooltip },
    });
  };

  const findExperimentHeader = () => wrapper.findComponent(TitleArea);
  const findDeleteButton = () => wrapper.findComponent(DeleteButton);
  const findDownloadButton = () => findExperimentHeader().findComponent(GlButton);
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findMetadataTab = () => findTabs().findAllComponents(GlTab).at(0);
  const findCandidatesTab = () => findTabs().findAllComponents(GlTab).at(1);
  const findPerformanceTab = () => findTabs().findAllComponents(GlTab).at(2);
  const findCandidatesCountBadge = () => findCandidatesTab().findComponent(GlBadge);
  const findCandidatesList = () => wrapper.findComponent(CandidateList);
  const findTimeAgoTooltip = () => findExperimentHeader().findComponent(TimeAgoTooltip);
  const findExperimentMetadata = () => wrapper.findByTestId('metadata');

  describe('default inputs', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows experiment header', () => {
      expect(findExperimentHeader().exists()).toBe(true);
    });

    it('sets model metadata correctly', () => {
      expect(findExperimentMetadata().findComponent(GlIcon).props('name')).toBe(
        'issue-type-test-case',
      );
      expect(findExperimentMetadata().text()).toBe('Experiment created in 2 years by root');

      expect(findTimeAgoTooltip().props('time')).toBe(MOCK_EXPERIMENT.created_at);

      expect(findExperimentMetadata().findComponent(GlLink).attributes('href')).toBe('/root');
      expect(findExperimentMetadata().findComponent(GlLink).text()).toBe('root');
    });

    it('passes the correct title to experiment header', () => {
      expect(findExperimentHeader().props('title')).toBe(MOCK_EXPERIMENT.name);
    });
  });

  describe('Delete', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows delete button', () => {
      expect(findDeleteButton().exists()).toBe(true);
    });

    it('passes the right props', () => {
      expect(findDeleteButton().props('deletePath')).toBe(MOCK_EXPERIMENT.path);
    });
  });

  describe('Delete with no permission', () => {
    beforeEach(() => {
      createWrapper({ canWriteModelExperiments: false });
    });

    it('does not show delete button', () => {
      expect(findDeleteButton().exists()).toBe(false);
    });
  });

  describe('With model id', () => {
    beforeEach(() => {
      createWrapper({ experiment: MOCK_MODEL_EXPERIMENT });
    });

    it('does not show delete button', () => {
      expect(findDeleteButton().exists()).toBe(false);
    });
  });

  describe('CSV download', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows download CSV button', () => {
      expect(findDownloadButton().exists()).toBe(true);
    });

    it('calls the action to download the CSV', () => {
      setWindowLocation('https://blah.com/something/1?name=query&orderBy=name');
      jest.spyOn(urlHelpers, 'visitUrl').mockImplementation(() => {});

      findDownloadButton().vm.$emit('click');

      expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
      expect(urlHelpers.visitUrl).toHaveBeenCalledWith('/something/1.csv?name=query&orderBy=name');
    });
  });

  describe('Tabs', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders tabs component', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('renders the correct tabs', () => {
      expect(findTabs().findAllComponents(GlTab).length).toBe(3);
    });

    it('renders metadata tab', () => {
      expect(findMetadataTab().attributes('title')).toBe('Overview');
    });

    it('renders runs tab', () => {
      expect(findCandidatesTab().text()).toContain('Runs');
    });

    it('renders performance tab', () => {
      expect(findPerformanceTab().attributes('title')).toBe('Performance');
    });

    it('shows the number of runs in the tab', () => {
      expect(findCandidatesCountBadge().text()).toBe(MOCK_CANDIDATES.length.toString());
    });

    it('sets the correct tab index based on route', async () => {
      await wrapper.vm.$router.push({ name: 'candidates' });
      expect(findTabs().props('value')).toBe(1);

      await wrapper.vm.$router.push({ name: 'details' });
      expect(findTabs().props('value')).toBe(0);

      await wrapper.vm.$router.push({ name: 'performance' });
      expect(findTabs().props('value')).toBe(2);
    });
  });

  describe('navigation', () => {
    beforeEach(() => {
      createWrapper({ mountFn: mountExtended });
    });

    it('navigates to the correct component when tab is clicked', async () => {
      findCandidatesTab().vm.$emit('click');
      await waitForPromises();

      expect(findTabs().props('value')).toBe(1);
      await waitForPromises();

      expect(findCandidatesList().exists()).toBe(true);
      expect(wrapper.findComponent(ExperimentMetadata).exists()).toBe(false);

      findMetadataTab().vm.$emit('click');
      await waitForPromises();

      expect(findTabs().props('value')).toBe(0);
      expect(wrapper.findComponent(ExperimentMetadata).exists()).toBe(true);
      expect(wrapper.findComponent(CandidateList).exists()).toBe(false);

      findPerformanceTab().vm.$emit('click');
      await waitForPromises();

      expect(findTabs().props('value')).toBe(2);
      expect(wrapper.findComponent(ExperimentMetadata).exists()).toBe(false);
      expect(wrapper.findComponent(PerformanceGraph).exists()).toBe(true);
    });
  });
});
