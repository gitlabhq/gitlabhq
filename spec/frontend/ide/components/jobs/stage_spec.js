import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Item from '~/ide/components/jobs/item.vue';
import Stage from '~/ide/components/jobs/stage.vue';
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

  const findHeader = () => wrapper.find('[data-testid="card-header"]');
  const findJobList = () => wrapper.find('[data-testid="job-list"]');
  const findStageTitle = () => wrapper.find('[data-testid="stage-title"]');

  const createComponent = (props) => {
    wrapper = shallowMount(Stage, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  it('emits fetch event when mounted', () => {
    createComponent();
    expect(wrapper.emitted().fetch).toBeDefined();
  });

  it('renders loading icon when no jobs and isLoading is true', () => {
    createComponent({
      stage: { ...defaultProps.stage, isLoading: true, jobs: [] },
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('emits toggleCollaped event with stage id when clicking header', async () => {
    const id = 5;
    createComponent({ stage: { ...defaultProps.stage, id } });
    findHeader().trigger('click');

    await nextTick();
    expect(wrapper.emitted().toggleCollapsed[0][0]).toBe(id);
  });

  it('emits clickViewLog entity with job', async () => {
    const [job] = defaultProps.stage.jobs;
    createComponent();
    wrapper.findAllComponents(Item).at(0).vm.$emit('clickViewLog', job);
    await nextTick();
    expect(wrapper.emitted().clickViewLog[0][0]).toBe(job);
  });

  it('renders stage title', () => {
    createComponent();
    expect(findStageTitle().isVisible()).toBe(true);
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
