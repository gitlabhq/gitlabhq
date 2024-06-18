import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PagesEdit from '~/gitlab_pages/components/pages_edit.vue';

Vue.use(VueApollo);

describe('PagesEdit', () => {
  let wrapper;
  const props = {};

  const createComponent = () => {
    wrapper = shallowMountExtended(PagesEdit, {
      propsData: props,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows the page header', () => {
    expect(wrapper.find('h1').text()).toBe('Pages');
  });
});
