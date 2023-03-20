import { merge } from 'lodash';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineUrlComponent from '~/pipelines/components/pipelines_list/pipeline_url.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { TRACKING_CATEGORIES } from '~/pipelines/constants';
import { mockPipeline, mockPipelineBranch, mockPipelineTag } from './mock_data';

const projectPath = 'test/test';

describe('Pipeline Url Component', () => {
  let wrapper;
  let trackingSpy;

  const findTableCell = () => wrapper.findByTestId('pipeline-url-table-cell');
  const findPipelineUrlLink = () => wrapper.findByTestId('pipeline-url-link');
  const findRefName = () => wrapper.findByTestId('merge-request-ref');
  const findCommitShortSha = () => wrapper.findByTestId('commit-short-sha');
  const findCommitIcon = () => wrapper.findByTestId('commit-icon');
  const findCommitIconType = () => wrapper.findByTestId('commit-icon-type');
  const findCommitRefName = () => wrapper.findByTestId('commit-ref-name');

  const findCommitTitleContainer = () => wrapper.findByTestId('commit-title-container');
  const findPipelineNameContainer = () => wrapper.findByTestId('pipeline-name-container');
  const findCommitTitle = (commitWrapper) => commitWrapper.find('[data-testid="commit-title"]');

  const defaultProps = mockPipeline(projectPath);

  const createComponent = (props) => {
    wrapper = shallowMountExtended(PipelineUrlComponent, {
      propsData: { ...defaultProps, ...props },
      provide: {
        targetProjectFullPath: projectPath,
      },
    });
  };

  it('should render pipeline url table cell', () => {
    createComponent();

    expect(findTableCell().exists()).toBe(true);
  });

  it('should render a link the provided path and id', () => {
    createComponent();

    expect(findPipelineUrlLink().attributes('href')).toBe('foo');

    expect(findPipelineUrlLink().text()).toBe('#1');
  });

  it('should render the pipeline name instead of commit title', () => {
    createComponent(merge(mockPipeline(projectPath), { pipeline: { name: 'Build pipeline' } }));

    expect(findCommitTitleContainer().exists()).toBe(false);
    expect(findPipelineNameContainer().exists()).toBe(true);
    expect(findRefName().exists()).toBe(true);
    expect(findCommitShortSha().exists()).toBe(true);
  });

  it('should render the commit title when pipeline has no name', () => {
    createComponent();

    const commitWrapper = findCommitTitleContainer();

    expect(findCommitTitle(commitWrapper).exists()).toBe(true);
    expect(findRefName().exists()).toBe(true);
    expect(findCommitShortSha().exists()).toBe(true);
    expect(findPipelineNameContainer().exists()).toBe(false);
  });

  describe('commit user avatar', () => {
    it('renders when commit author exists', () => {
      const pipelineBranch = mockPipelineBranch();
      const { avatar_url: imgSrc, name, path } = pipelineBranch.pipeline.commit.author;
      createComponent(pipelineBranch);

      const component = wrapper.findComponent(UserAvatarLink);
      expect(component.exists()).toBe(true);
      expect(component.props()).toMatchObject({
        imgSize: 16,
        imgSrc,
        imgAlt: name,
        linkHref: path,
        tooltipText: name,
      });
    });

    it('does not render when commit author does not exist', () => {
      createComponent();

      expect(wrapper.findComponent(UserAvatarLink).exists()).toBe(false);
    });
  });

  it('should render commit icon tooltip', () => {
    createComponent();

    expect(findCommitIcon().attributes('title')).toBe('Commit');
  });

  it.each`
    pipeline                | expectedTitle
    ${mockPipelineTag()}    | ${'Tag'}
    ${mockPipelineBranch()} | ${'Branch'}
    ${mockPipeline()}       | ${'Merge Request'}
  `('should render tooltip $expectedTitle for commit icon type', ({ pipeline, expectedTitle }) => {
    createComponent(pipeline);

    expect(findCommitIconType().attributes('title')).toBe(expectedTitle);
  });

  describe('tracking', () => {
    beforeEach(() => {
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks pipeline id click', () => {
      createComponent();

      findPipelineUrlLink().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_pipeline_id', {
        label: TRACKING_CATEGORIES.table,
      });
    });

    it('tracks merge request ref click', () => {
      createComponent();

      findRefName().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_mr_ref', {
        label: TRACKING_CATEGORIES.table,
      });
    });

    it('tracks commit ref name click', () => {
      createComponent(mockPipelineBranch());

      findCommitRefName().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_commit_name', {
        label: TRACKING_CATEGORIES.table,
      });
    });

    it('tracks commit title click', () => {
      createComponent(merge(mockPipelineBranch(), { pipeline: { name: null } }));

      findCommitTitle(findCommitTitleContainer()).vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_commit_title', {
        label: TRACKING_CATEGORIES.table,
      });
    });

    it('tracks commit short sha click', () => {
      createComponent(mockPipelineBranch());

      findCommitShortSha().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_commit_sha', {
        label: TRACKING_CATEGORIES.table,
      });
    });
  });
});
