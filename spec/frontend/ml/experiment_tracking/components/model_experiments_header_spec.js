import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

describe('ml/experiment_tracking/components/model_experiments_header.vue', () => {
  let wrapper;

  const createWrapper = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ModelExperimentsHeader, {
      propsData: { pageTitle: 'Some Title', count: 2, ...propsData },
      slots: {
        default: 'Slot content',
      },
    });
  };

  beforeEach(createWrapper);

  const findTitle = () => wrapper.findByTestId('page-heading');
  const findCount = () => wrapper.findByTestId('count');
  const findCountIcon = () => wrapper.findComponent(GlIcon);
  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findDropdown = () => wrapper.findByTestId('create-dropdown');
  const findMenuItem = () => wrapper.findByTestId('create-menu-item');

  it('title area exists', () => {
    expect(findTitleArea().exists()).toBe(true);
  });

  it('title is set', () => {
    expect(findTitle().text()).toContain('Some Title');
  });

  it('count area is set', () => {
    expect(findCount().text()).toBe('2 experiments');
  });

  it('count area exists', () => {
    expect(findCountIcon().props()).toMatchObject({
      name: 'issue-type-test-case',
    });
  });

  it('dropdown exists', () => {
    expect(findDropdown().props()).toMatchObject({
      toggleText: 'Create',
      variant: 'confirm',
      category: 'primary',
    });
  });

  it('a menu item for creating experiments exist', () => {
    expect(findMenuItem().props()).toMatchObject({
      item: {
        text: 'Create experiments using MLflow',
      },
    });
  });

  it('renders slots', () => {
    expect(wrapper.html()).toContain('Slot content');
  });
});
