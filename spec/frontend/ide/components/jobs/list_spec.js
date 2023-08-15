import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import StageList from '~/ide/components/jobs/list.vue';
import Stage from '~/ide/components/jobs/stage.vue';

Vue.use(Vuex);
const storeActions = {
  fetchJobs: jest.fn(),
  toggleStageCollapsed: jest.fn(),
  setDetailJob: jest.fn(),
};

const store = new Vuex.Store({
  modules: {
    pipelines: {
      namespaced: true,
      actions: storeActions,
    },
  },
});

describe('IDE stages list', () => {
  let wrapper;

  const defaultProps = {
    stages: [],
    loading: false,
  };

  const stages = ['build', 'test', 'deploy'].map((name, id) => ({
    id,
    name,
    jobs: [],
    status: { icon: 'status_success' },
  }));

  const createComponent = (props) => {
    wrapper = shallowMount(StageList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      store,
    });
  };

  afterEach(() => {
    Object.values(storeActions).forEach((actionMock) => actionMock.mockClear());
  });

  it('renders loading icon when no stages & loading', () => {
    createComponent({ loading: true, stages: [] });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders stages components for each stage', () => {
    createComponent({ stages });
    expect(wrapper.findAllComponents(Stage).length).toBe(stages.length);
  });

  it('triggers fetchJobs action when stage emits fetch event', () => {
    createComponent({ stages });
    wrapper.findComponent(Stage).vm.$emit('fetch');
    expect(storeActions.fetchJobs).toHaveBeenCalled();
  });

  it('triggers toggleStageCollapsed action when stage emits toggleCollapsed event', () => {
    createComponent({ stages });
    wrapper.findComponent(Stage).vm.$emit('toggleCollapsed');
    expect(storeActions.toggleStageCollapsed).toHaveBeenCalled();
  });

  it('triggers setDetailJob action when stage emits clickViewLog event', () => {
    createComponent({ stages });
    wrapper.findComponent(Stage).vm.$emit('clickViewLog');
    expect(storeActions.setDetailJob).toHaveBeenCalled();
  });

  describe('integration tests', () => {
    const findCardHeader = () => wrapper.find('.card-header');

    beforeEach(() => {
      wrapper = mount(StageList, {
        propsData: { ...defaultProps, stages },
        store,
      });
    });

    it('calls toggleStageCollapsed when clicking stage header', () => {
      findCardHeader().trigger('click');

      expect(storeActions.toggleStageCollapsed).toHaveBeenCalledWith(expect.any(Object), 0);
    });

    it('calls fetchJobs when stage is mounted', () => {
      expect(storeActions.fetchJobs.mock.calls.map(([, stage]) => stage)).toEqual(stages);
    });
  });
});
