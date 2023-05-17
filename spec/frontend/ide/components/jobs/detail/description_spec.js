import { mount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import Description from '~/ide/components/jobs/detail/description.vue';
import { jobs } from '../../../mock_data';

describe('IDE job description', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(Description, {
      propsData: {
        job: jobs[0],
      },
    });
  });

  it('renders job details', () => {
    expect(wrapper.text()).toContain('#1');
    expect(wrapper.text()).toContain('test');
  });

  it('renders CI icon', () => {
    expect(wrapper.find('.ci-status-icon').findComponent(GlIcon).exists()).toBe(true);
  });

  it('renders a borderless CI icon', () => {
    expect(wrapper.find('.borderless').findComponent(GlIcon).exists()).toBe(true);
  });

  it('renders bridge job details without the job link', () => {
    wrapper = mount(Description, {
      propsData: {
        job: { ...jobs[0], path: undefined },
      },
    });

    expect(wrapper.find('[data-testid="description-detail-link"]').exists()).toBe(false);
  });
});
