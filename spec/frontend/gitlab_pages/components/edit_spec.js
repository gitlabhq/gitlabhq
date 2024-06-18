import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PagesEdit from '~/gitlab_pages/components/edit.vue';
import PagesDeployments from '~/gitlab_pages/components/deployments.vue';

Vue.use(VueApollo);

describe('PagesEdit', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(PagesEdit);
  };

  beforeEach(() => {
    createComponent();
  });

  it('mounts the PagesDeployments component', () => {
    expect(wrapper.findComponent(PagesDeployments).exists()).toBe(true);
  });
});
