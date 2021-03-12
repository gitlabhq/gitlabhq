import { shallowMount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import PipelineUrlComponent from '~/pipelines/components/pipelines_list/pipeline_url.vue';

const projectPath = 'test/test';

describe('Pipeline Url Component', () => {
  let wrapper;

  const findTableCell = () => wrapper.find('[data-testid="pipeline-url-table-cell"]');
  const findPipelineUrlLink = () => wrapper.find('[data-testid="pipeline-url-link"]');
  const findScheduledTag = () => wrapper.find('[data-testid="pipeline-url-scheduled"]');
  const findLatestTag = () => wrapper.find('[data-testid="pipeline-url-latest"]');
  const findYamlTag = () => wrapper.find('[data-testid="pipeline-url-yaml"]');
  const findFailureTag = () => wrapper.find('[data-testid="pipeline-url-failure"]');
  const findAutoDevopsTag = () => wrapper.find('[data-testid="pipeline-url-autodevops"]');
  const findAutoDevopsTagLink = () => wrapper.find('[data-testid="pipeline-url-autodevops-link"]');
  const findStuckTag = () => wrapper.find('[data-testid="pipeline-url-stuck"]');
  const findDetachedTag = () => wrapper.find('[data-testid="pipeline-url-detached"]');
  const findForkTag = () => wrapper.find('[data-testid="pipeline-url-fork"]');
  const findTrainTag = () => wrapper.find('[data-testid="pipeline-url-train"]');

  const defaultProps = {
    pipeline: {
      id: 1,
      path: 'foo',
      project: { full_path: `/${projectPath}` },
      flags: {},
    },
    pipelineScheduleUrl: 'foo',
  };

  const createComponent = (props) => {
    wrapper = shallowMount(PipelineUrlComponent, {
      propsData: { ...defaultProps, ...props },
      provide: {
        targetProjectFullPath: projectPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render pipeline url table cell', () => {
    createComponent();

    expect(findTableCell().exists()).toBe(true);
  });

  it('should render a link the provided path and id', () => {
    createComponent();

    expect(findPipelineUrlLink().attributes('href')).toBe('foo');

    expect(findPipelineUrlLink().text()).toBe('#1');
  });

  it('should not render tags when flags are not set', () => {
    createComponent();

    expect(findStuckTag().exists()).toBe(false);
    expect(findLatestTag().exists()).toBe(false);
    expect(findYamlTag().exists()).toBe(false);
    expect(findAutoDevopsTag().exists()).toBe(false);
    expect(findFailureTag().exists()).toBe(false);
    expect(findScheduledTag().exists()).toBe(false);
    expect(findForkTag().exists()).toBe(false);
    expect(findTrainTag().exists()).toBe(false);
  });

  it('should render the stuck tag when flag is provided', () => {
    createComponent({
      pipeline: {
        flags: {
          stuck: true,
        },
      },
    });

    expect(findStuckTag().text()).toContain('stuck');
  });

  it('should render latest tag when flag is provided', () => {
    createComponent({
      pipeline: {
        flags: {
          latest: true,
        },
      },
    });

    expect(findLatestTag().text()).toContain('latest');
  });

  it('should render a yaml badge when it is invalid', () => {
    createComponent({
      pipeline: {
        flags: {
          yaml_errors: true,
        },
      },
    });

    expect(findYamlTag().text()).toContain('yaml invalid');
  });

  it('should render an autodevops badge when flag is provided', () => {
    createComponent({
      pipeline: {
        ...defaultProps.pipeline,
        flags: {
          auto_devops: true,
        },
      },
    });

    expect(trimText(findAutoDevopsTag().text())).toBe('Auto DevOps');

    expect(findAutoDevopsTagLink().attributes()).toMatchObject({
      href: '/help/topics/autodevops/index.md',
      target: '_blank',
    });
  });

  it('should render a detached badge when flag is provided', () => {
    createComponent({
      pipeline: {
        flags: {
          detached_merge_request_pipeline: true,
        },
      },
    });

    expect(findDetachedTag().text()).toContain('detached');
  });

  it('should render error badge when pipeline has a failure reason set', () => {
    createComponent({
      pipeline: {
        flags: {
          failure_reason: true,
        },
        failure_reason: 'some reason',
      },
    });

    expect(findFailureTag().text()).toContain('error');
    expect(findFailureTag().attributes('title')).toContain('some reason');
  });

  it('should render scheduled badge when pipeline was triggered by a schedule', () => {
    createComponent({
      pipeline: {
        flags: {},
        source: 'schedule',
      },
    });

    expect(findScheduledTag().exists()).toBe(true);
    expect(findScheduledTag().text()).toContain('Scheduled');
  });

  it('should render the fork badge when the pipeline was run in a fork', () => {
    createComponent({
      pipeline: {
        flags: {},
        project: { fullPath: '/test/forked' },
      },
    });

    expect(findForkTag().exists()).toBe(true);
    expect(findForkTag().text()).toBe('fork');
  });

  it('should render the train badge when the pipeline is a merge train pipeline', () => {
    createComponent({
      pipeline: {
        flags: {
          merge_train_pipeline: true,
        },
      },
    });

    expect(findTrainTag().text()).toContain('train');
  });

  it('should not render the train badge when the pipeline is not a merge train pipeline', () => {
    createComponent({
      pipeline: {
        flags: {
          merge_train_pipeline: false,
        },
      },
    });

    expect(findTrainTag().exists()).toBe(false);
  });
});
