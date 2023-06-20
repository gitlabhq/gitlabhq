import { GlLink, GlSprintf } from '@gitlab/ui';
import ServicesItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/services_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  HELP_PATHS,
  JOB_TEMPLATE,
} from '~/ci/pipeline_editor/components/job_assistant_drawer/constants';

describe('Services item', () => {
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);
  const findServiceNameInputByIndex = (index) =>
    wrapper.findByTestId(`service-name-input-${index}`);
  const findServiceEntrypointInputByIndex = (index) =>
    wrapper.findByTestId(`service-entrypoint-input-${index}`);
  const findDeleteItemButtonByIndex = (index) =>
    wrapper.findByTestId(`delete-job-service-button-${index}`);
  const findAddItemButton = () => wrapper.findByTestId('add-job-service-button');

  const dummyServiceName = 'a';
  const dummyServiceEntrypoint = ['b', 'c'];

  const createComponent = ({ job = JSON.parse(JSON.stringify(JOB_TEMPLATE)) } = {}) => {
    wrapper = shallowMountExtended(ServicesItem, {
      propsData: {
        job,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  it('should render help links with correct hrefs', () => {
    createComponent();

    expect(findLink().attributes('href')).toEqual(HELP_PATHS.servicesHelpPath);
  });

  it('should emit update job event when filling inputs', () => {
    createComponent();

    expect(wrapper.emitted('update-job')).toBeUndefined();

    findServiceNameInputByIndex(0).vm.$emit('input', dummyServiceName);

    expect(wrapper.emitted('update-job')).toHaveLength(1);
    expect(wrapper.emitted('update-job')[0]).toEqual(['services[0].name', dummyServiceName]);

    findServiceEntrypointInputByIndex(0).vm.$emit('input', dummyServiceEntrypoint.join('\n'));

    expect(wrapper.emitted('update-job')).toHaveLength(2);
    expect(wrapper.emitted('update-job')[1]).toEqual([
      'services[0].entrypoint',
      dummyServiceEntrypoint,
    ]);
  });

  it('should emit update job event when click add item button', () => {
    createComponent();

    findAddItemButton().vm.$emit('click');

    expect(wrapper.emitted('update-job')).toHaveLength(1);
    expect(wrapper.emitted('update-job')[0]).toEqual([
      'services[1]',
      { name: '', entrypoint: [''] },
    ]);
  });

  it('should emit update job event when click delete item button', () => {
    createComponent({
      job: {
        services: [
          { name: 'a', entrypoint: ['a'] },
          { name: 'b', entrypoint: ['b'] },
        ],
      },
    });

    findDeleteItemButtonByIndex(0).vm.$emit('click');

    expect(wrapper.emitted('update-job')).toHaveLength(1);
    expect(wrapper.emitted('update-job')[0]).toEqual(['services[0]']);
  });

  it('should not show delete item button when there is only one service', () => {
    createComponent();

    expect(findDeleteItemButtonByIndex(0).exists()).toBe(false);
  });
});
