import { GlLink, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NewCluster from '~/clusters/components/new_cluster.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

describe('NewCluster', () => {
  let wrapper;

  const createWrapper = async () => {
    wrapper = shallowMountExtended(NewCluster, { stubs: { GlLink, GlSprintf } });
    await nextTick();
  };

  const findDescription = () => wrapper.findByTestId('description');

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
