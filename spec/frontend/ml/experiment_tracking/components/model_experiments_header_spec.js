import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

describe('ml/experiment_tracking/components/model_experiments_header.vue', () => {
  let wrapper;

  const createWrapper = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ModelExperimentsHeader, {
      propsData: { pageTitle: 'Some Title', ...propsData },
      slots: {
        default: 'Slot content',
      },
    });
  };

  beforeEach(createWrapper);

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findTitle = () => wrapper.findByTestId('page-heading');
  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findDropdown = () => wrapper.findByTestId('create-dropdown');
  const findMenuItem = () => wrapper.findByTestId('create-menu-item');

  it('title area exists', () => {
    expect(findTitleArea().exists()).toBe(true);
  });

  it('title is set', () => {
    expect(findTitle().text()).toContain('Some Title');
  });

  it('dropdown exists', () => {
    expect(findDropdown().props()).toMatchObject({
      toggleText: 'Create',
      variant: 'confirm',
      category: 'primary',
    });
  });

  it('dropdown is hidden when hideMlflowUsage is true', () => {
    createWrapper({ propsData: { hideMlflowUsage: true } });
    expect(findDropdown().exists()).toBe(false);
  });

  it('a menu item for creating experiments exist', () => {
    expect(findMenuItem().props()).toMatchObject({
      item: {
        text: 'Create experiments using MLflow',
      },
    });
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
