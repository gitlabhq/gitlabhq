import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlSprintf } from '@gitlab/ui';
import PageTitle from '~/kubernetes_dashboard/components/page_title.vue';

const agent = {
  name: 'my-agent',
  id: '123',
};

let wrapper;

const createWrapper = () => {
  wrapper = shallowMount(PageTitle, {
    provide: {
      agent,
    },
    stubs: { GlSprintf },
  });
};

const findIcon = () => wrapper.findComponent(GlIcon);

describe('Page title component', () => {
  it('renders Kubernetes agent icon', () => {
    createWrapper();

    expect(findIcon().props('name')).toBe('kubernetes-agent');
  });

  it('renders agent information', () => {
    createWrapper();

    expect(wrapper.text()).toMatchInterpolatedText('Agent my-agent ID #123');
  });
});
