import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import Stage from '~/ide/components/jobs/stage.vue';
import Item from '~/ide/components/jobs/item.vue';
import { stages, jobs } from '../../mock_data';

describe('IDE pipeline stage', () => {
  let wrapper;
  const defaultProps = {
    stage: {
      ...stages[0],
      id: 0,
      dropdownPath: stages[0].dropdown_path,
      jobs: [...jobs],
      isLoading: false,
      isCollapsed: false,
    },
  };

  const findHeader = () => wrapper.find({ ref: 'cardHeader' });
  const findJobList = () => wrapper.find({ ref: 'jobList' });

  const createComponent = props => {
    wrapper = shallowMount(Stage, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('emits fetch event when mounted', () => {
    createComponent();
    expect(wrapper.emitted().fetch).toBeDefined();
  });

  it('renders loading icon when no jobs and isLoading is true', () => {
    createComponent({
      stage: { ...defaultProps.stage, isLoading: true, jobs: [] },
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('emits toggleCollaped event with stage id when clicking header', () => {
    const id = 5;
    createComponent({ stage: { ...defaultProps.stage, id } });
    findHeader().trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted().toggleCollapsed[0][0]).toBe(id);
    });
  });

  it('emits clickViewLog entity with job', () => {
    const [job] = defaultProps.stage.jobs;
    createComponent();
    wrapper
      .findAll(Item)
      .at(0)
      .vm.$emit('clickViewLog', job);
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted().clickViewLog[0][0]).toBe(job);
    });
  });

  it('renders stage details & icon', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when collapsed', () => {
    beforeEach(() => {
      createComponent({ stage: { ...defaultProps.stage, isCollapsed: true } });
    });

    it('does not render job list', () => {
      expect(findJobList().isVisible()).toBe(false);
    });

    it('sets border bottom class', () => {
      expect(findHeader().classes('border-bottom-0')).toBe(true);
    });
  });
});
