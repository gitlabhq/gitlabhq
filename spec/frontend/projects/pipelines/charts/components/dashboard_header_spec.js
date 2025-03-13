import { shallowMount } from '@vue/test-utils';
import DashboardHeader from '~/projects/pipelines/charts/components/dashboard_header.vue';

describe('DashboardHeader', () => {
  let wrapper;

  const createComponent = ({ ...options }) => {
    wrapper = shallowMount(DashboardHeader, { ...options });
  };

  it('shows heading', () => {
    createComponent({
      slots: {
        default: 'My Heading',
      },
    });

    expect(wrapper.find('h2').text()).toBe('My Heading');
  });

  it('shows description', () => {
    createComponent({
      slots: {
        description: '<p>My Description</p>',
      },
    });

    expect(wrapper.find('p').text()).toContain('My Description');
  });
});
