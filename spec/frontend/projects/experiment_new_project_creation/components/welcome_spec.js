import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { mockTracking } from 'helpers/tracking_helper';
import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { getExperimentData } from '~/experimentation/utils';
import NewProjectPushTipPopover from '~/projects/experiment_new_project_creation/components/new_project_push_tip_popover.vue';
import WelcomePage from '~/projects/experiment_new_project_creation/components/welcome.vue';

jest.mock('~/experimentation/utils', () => ({ getExperimentData: jest.fn() }));

describe('Welcome page', () => {
  let wrapper;
  let trackingSpy;

  const createComponent = (propsData) => {
    wrapper = shallowMount(WelcomePage, { propsData });
  };

  beforeEach(() => {
    trackingSpy = mockTracking('_category_', document, jest.spyOn);
    trackingSpy.mockImplementation(() => {});
    getExperimentData.mockReturnValue(undefined);
  });

  afterEach(() => {
    wrapper.destroy();
    window.location.hash = '';
    wrapper = null;
  });

  it('tracks link clicks', async () => {
    createComponent({ panels: [{ name: 'test', href: '#' }] });
    const link = wrapper.find('a');
    link.trigger('click');
    await nextTick();
    return wrapper.vm.$nextTick().then(() => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_tab', { label: 'test' });
    });
  });

  it('adds new_repo experiment data if in experiment', async () => {
    const mockExperimentData = 'data';
    getExperimentData.mockReturnValue(mockExperimentData);

    createComponent({ panels: [{ name: 'test', href: '#' }] });
    const link = wrapper.find('a');
    link.trigger('click');
    await nextTick();
    return wrapper.vm.$nextTick().then(() => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_tab', {
        label: 'test',
        context: {
          data: mockExperimentData,
          schema: TRACKING_CONTEXT_SCHEMA,
        },
      });
    });
  });

  it('renders new project push tip popover', () => {
    createComponent({ panels: [{ name: 'test', href: '#' }] });

    const popover = wrapper.findComponent(NewProjectPushTipPopover);

    expect(popover.exists()).toBe(true);
    expect(popover.props().target()).toBe(wrapper.find({ ref: 'clipTip' }).element);
  });
});
