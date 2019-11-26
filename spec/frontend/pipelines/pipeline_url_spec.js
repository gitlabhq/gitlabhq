import $ from 'jquery';
import { trimText } from 'helpers/text_helper';
import { shallowMount } from '@vue/test-utils';
import PipelineUrlComponent from '~/pipelines/components/pipeline_url.vue';

$.fn.popover = () => {};

describe('Pipeline Url Component', () => {
  let wrapper;

  const createComponent = props => {
    wrapper = shallowMount(PipelineUrlComponent, {
      sync: false,
      attachToDocument: true,
      propsData: props,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render a table cell', () => {
    createComponent({
      pipeline: {
        id: 1,
        path: 'foo',
        flags: {},
      },
      autoDevopsHelpPath: 'foo',
    });

    expect(wrapper.attributes('class')).toContain('table-section');
  });

  it('should render a link the provided path and id', () => {
    createComponent({
      pipeline: {
        id: 1,
        path: 'foo',
        flags: {},
      },
      autoDevopsHelpPath: 'foo',
    });

    expect(wrapper.find('.js-pipeline-url-link').attributes('href')).toBe('foo');

    expect(wrapper.find('.js-pipeline-url-link span').text()).toBe('#1');
  });

  it('should render latest, yaml invalid, merge request, and stuck flags when provided', () => {
    createComponent({
      pipeline: {
        id: 1,
        path: 'foo',
        flags: {
          latest: true,
          yaml_errors: true,
          stuck: true,
          merge_request_pipeline: true,
          detached_merge_request_pipeline: true,
        },
      },
      autoDevopsHelpPath: 'foo',
    });

    expect(wrapper.find('.js-pipeline-url-latest').text()).toContain('latest');

    expect(wrapper.find('.js-pipeline-url-yaml').text()).toContain('yaml invalid');

    expect(wrapper.find('.js-pipeline-url-stuck').text()).toContain('stuck');

    expect(wrapper.find('.js-pipeline-url-detached').text()).toContain('detached');
  });

  it('should render a badge for autodevops', () => {
    createComponent({
      pipeline: {
        id: 1,
        path: 'foo',
        flags: {
          latest: true,
          yaml_errors: true,
          stuck: true,
          auto_devops: true,
        },
      },
      autoDevopsHelpPath: 'foo',
    });

    expect(trimText(wrapper.find('.js-pipeline-url-autodevops').text())).toEqual('Auto DevOps');
  });

  it('should render error badge when pipeline has a failure reason set', () => {
    createComponent({
      pipeline: {
        id: 1,
        path: 'foo',
        flags: {
          failure_reason: true,
        },
        failure_reason: 'some reason',
      },
      autoDevopsHelpPath: 'foo',
    });

    expect(wrapper.find('.js-pipeline-url-failure').text()).toContain('error');
    expect(wrapper.find('.js-pipeline-url-failure').attributes('data-original-title')).toContain(
      'some reason',
    );
  });
});
