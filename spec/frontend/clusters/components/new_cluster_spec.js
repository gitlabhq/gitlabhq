import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import NewCluster from '~/clusters/components/new_cluster.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

describe('NewCluster', () => {
  let wrapper;

  const createWrapper = async () => {
    wrapper = shallowMount(NewCluster, { stubs: { GlLink, GlSprintf } });
    await nextTick();
  };

  const findDescription = () => wrapper.findComponent(GlSprintf);

  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    return createWrapper();
  });

  it('renders the cluster component correctly', () => {
    expect(wrapper.html()).toMatchSnapshot();
  });

  it('renders the correct information text', () => {
    expect(findDescription().text()).toContain('Enter details about your cluster.');
  });

  it('renders a valid help link set by the backend', () => {
    expect(findLink().attributes('href')).toBe(
      helpPagePath('user/project/clusters/add_existing_cluster'),
    );
  });
});
