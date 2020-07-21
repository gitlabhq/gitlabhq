import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import PackageActivity from '~/packages/details/components/activity.vue';
import {
  npmPackage,
  mavenPackage as packageWithoutBuildInfo,
  mockPipelineInfo,
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('PackageActivity', () => {
  let wrapper;
  let store;

  function createComponent(packageEntity = packageWithoutBuildInfo, pipelineInfo = null) {
    store = new Vuex.Store({
      state: {
        packageEntity,
      },
      getters: {
        packagePipeline: () => pipelineInfo,
      },
    });

    wrapper = shallowMount(PackageActivity, {
      localVue,
      store,
    });
  }

  const commitMessageToggle = () => wrapper.find({ ref: 'commit-message-toggle' });
  const commitMessage = () => wrapper.find({ ref: 'commit-message' });
  const commitInfo = () => wrapper.find({ ref: 'commit-info' });
  const pipelineInfo = () => wrapper.find({ ref: 'pipeline-info' });

  afterEach(() => {
    if (wrapper) wrapper.destroy();
    wrapper = null;
  });

  describe('render', () => {
    it('to match the default snapshot when no pipeline', () => {
      createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('to match the default snapshot when there is a pipeline', () => {
      createComponent(npmPackage, mockPipelineInfo);

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('commit message toggle', () => {
    it("does not display the commit message button when there isn't one", () => {
      createComponent(npmPackage, mockPipelineInfo);

      expect(commitMessageToggle().exists()).toBe(false);
      expect(commitMessage().exists()).toBe(false);
    });

    it('displays the commit message on toggle', () => {
      const commitMessageStr = 'a message';
      createComponent(npmPackage, {
        ...mockPipelineInfo,
        git_commit_message: commitMessageStr,
      });

      commitMessageToggle().trigger('click');

      return wrapper.vm.$nextTick(() => expect(commitMessage().text()).toBe(commitMessageStr));
    });
  });

  describe('pipeline information', () => {
    it('does not display pipeline information when no build info is available', () => {
      createComponent();

      expect(pipelineInfo().exists()).toBe(false);
    });

    it('displays the pipeline information if found', () => {
      createComponent(npmPackage, mockPipelineInfo);

      expect(commitInfo().exists()).toBe(true);
      expect(pipelineInfo().exists()).toBe(true);
    });
  });
});
