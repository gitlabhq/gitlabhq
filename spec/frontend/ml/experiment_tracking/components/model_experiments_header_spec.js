import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';

describe('ml/experiment_tracking/components/model_experiments_header.vue', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMountExtended(ModelExperimentsHeader, {
      propsData: { pageTitle: 'Some Title' },
      slots: {
        default: 'Slot content',
      },
      stubs: {
        PageHeading,
      },
    });
  };

  beforeEach(createWrapper);

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findTitle = () => wrapper.findByTestId('page-heading');

  it('renders title', () => {
    expect(findTitle().text()).toContain('Some Title');
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
