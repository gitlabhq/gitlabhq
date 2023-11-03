import { mount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';

import JobItem from '~/ide/components/jobs/item.vue';
import { jobs } from '../../mock_data';

describe('IDE jobs item', () => {
  const job = jobs[0];
  let wrapper;

  beforeEach(() => {
    wrapper = mount(JobItem, { propsData: { job } });
  });

  it('renders job details', () => {
    expect(wrapper.text()).toContain(job.name);
    expect(wrapper.text()).toContain(`#${job.id}`);
  });

  it('renders CI icon', () => {
    expect(wrapper.find('[data-testid="ci-icon"]').exists()).toBe(true);
  });

  it('does not render view logs button if not started', async () => {
    await wrapper.setProps({
      job: {
        ...jobs[0],
        started: false,
      },
    });

    expect(wrapper.findComponent(GlButton).exists()).toBe(false);
  });
});
