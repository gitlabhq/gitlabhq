import { shallowMount } from '@vue/test-utils';
import DevopsAdoptionApp from '~/admin/dev_ops_report/components/devops_adoption_app.vue';
import DevopsAdoptionEmptyState from '~/admin/dev_ops_report/components/devops_adoption_empty_state.vue';

describe('DevopsAdoptionApp', () => {
  let wrapper;

  const createComponent = () => {
    return shallowMount(DevopsAdoptionApp);
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('default behaviour', () => {
    it('displays the empty state', () => {
      expect(wrapper.find(DevopsAdoptionEmptyState).exists()).toBe(true);
    });
  });
});
