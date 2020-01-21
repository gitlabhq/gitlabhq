import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import Vuex from 'vuex';
import StageList from '~/ide/components/jobs/list.vue';
import Stage from '~/ide/components/jobs/stage.vue';

const localVue = createLocalVue();
localVue.use(Vuex);
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

  const createComponent = props => {
    wrapper = shallowMount(StageList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      localVue,
      store,
    });
  };

  afterEach(() => {
    Object.values(storeActions).forEach(actionMock => actionMock.mockClear());
  });

  afterAll(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders loading icon when no stages & loading', () => {
    createComponent({ loading: true, stages: [] });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders stages components for each stage', () => {
    createComponent({ stages });
    expect(wrapper.findAll(Stage).length).toBe(stages.length);
  });

  it('triggers fetchJobs action when stage emits fetch event', () => {
    createComponent({ stages });
    wrapper.find(Stage).vm.$emit('fetch');
    expect(storeActions.fetchJobs).toHaveBeenCalled();
  });

  it('triggers toggleStageCollapsed action when stage emits toggleCollapsed event', () => {
    createComponent({ stages });
    wrapper.find(Stage).vm.$emit('toggleCollapsed');
    expect(storeActions.toggleStageCollapsed).toHaveBeenCalled();
  });

  it('triggers setDetailJob action when stage emits clickViewLog event', () => {
    createComponent({ stages });
    wrapper.find(Stage).vm.$emit('clickViewLog');
    expect(storeActions.setDetailJob).toHaveBeenCalled();
  });

  describe('integration tests', () => {
    const findCardHeader = () => wrapper.find('.card-header');

    beforeEach(() => {
      wrapper = mount(StageList, {
        propsData: { ...defaultProps, stages },
        store,
        localVue,
      });
    });

    it('calls toggleStageCollapsed when clicking stage header', () => {
      findCardHeader().trigger('click');

      expect(storeActions.toggleStageCollapsed).toHaveBeenCalledWith(
        expect.any(Object),
        0,
        undefined,
      );
    });

    it('calls fetchJobs when stage is mounted', () => {
      expect(storeActions.fetchJobs.mock.calls.map(([, stage]) => stage)).toEqual(stages);
    });
  });
});
