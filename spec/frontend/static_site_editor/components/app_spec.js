import { shallowMount } from '@vue/test-utils';
import App from '~/static_site_editor/components/app.vue';

describe('static_site_editor/components/app', () => {
  const mergeRequestsIllustrationPath = 'illustrations/merge_requests.svg';
  const RouterView = {
    template: '<div></div>',
  };
  let wrapper;

  const buildWrapper = () => {
    wrapper = shallowMount(App, {
      stubs: {
        RouterView,
      },
      propsData: {
        mergeRequestsIllustrationPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('passes merge request illustration path to the router view component', () => {
    buildWrapper();

    expect(wrapper.find(RouterView).attributes()).toMatchObject({
      'merge-requests-illustration-path': mergeRequestsIllustrationPath,
    });
  });
});
