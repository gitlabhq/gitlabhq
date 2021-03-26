import { mount } from '@vue/test-utils';
import jobNameComponent from '~/pipelines/components/jobs_shared/job_name_component.vue';
import ciIcon from '~/vue_shared/components/ci_icon.vue';

describe('job name component', () => {
  let wrapper;

  const propsData = {
    name: 'foo',
    status: {
      icon: 'status_success',
      group: 'success',
    },
  };

  beforeEach(() => {
    wrapper = mount(jobNameComponent, {
      propsData,
    });
  });

  it('should render the provided name', () => {
    expect(wrapper.text()).toBe(propsData.name);
  });

  it('should render an icon with the provided status', () => {
    expect(wrapper.find(ciIcon).exists()).toBe(true);
    expect(wrapper.find('.ci-status-icon-success').exists()).toBe(true);
  });
});
