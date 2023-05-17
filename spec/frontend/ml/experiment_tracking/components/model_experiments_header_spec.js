import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';

describe('ml/experiment_tracking/components/model_experiments_header.vue', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(ModelExperimentsHeader, {
      propsData: { pageTitle: 'Some Title' },
      slots: {
        default: 'Slot content',
      },
    });
  };

  beforeEach(createWrapper);

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findTitle = () => wrapper.find('h3');

  it('renders title', () => {
    expect(findTitle().text()).toBe('Some Title');
  });

  it('link points to documentation', () => {
    expect(findBadge().attributes().href).toBe(
      '/help/user/project/ml/experiment_tracking/index.md',
    );
  });

  it('renders slots', () => {
    expect(wrapper.html()).toContain('Slot content');
  });
});
