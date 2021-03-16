import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import PipelinesTableRowComponent from '~/pipelines/components/pipelines_list/pipelines_table_row.vue';
import eventHub from '~/pipelines/event_hub';

describe('Pipelines Table Row', () => {
  const jsonFixtureName = 'pipelines/pipelines.json';

  const createWrapper = (pipeline) =>
    mount(PipelinesTableRowComponent, {
      propsData: {
        pipeline,
        viewType: 'root',
      },
    });

  let wrapper;
  let pipeline;
  let pipelineWithoutAuthor;
  let pipelineWithoutCommit;

  beforeEach(() => {
    const { pipelines } = getJSONFixture(jsonFixtureName);

    pipeline = pipelines.find((p) => p.user !== null && p.commit !== null);
    pipelineWithoutAuthor = pipelines.find((p) => p.user === null && p.commit !== null);
    pipelineWithoutCommit = pipelines.find((p) => p.user === null && p.commit === null);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render a table row', () => {
    wrapper = createWrapper(pipeline);

    expect(wrapper.attributes('class')).toContain('gl-responsive-table-row');
  });

  describe('status column', () => {
    beforeEach(() => {
      wrapper = createWrapper(pipeline);
    });

    it('should render a pipeline link', () => {
      expect(wrapper.find('.table-section.commit-link a').attributes('href')).toEqual(
        pipeline.path,
      );
    });

    it('should render status text', () => {
      expect(wrapper.find('.table-section.commit-link a').text()).toContain(
        pipeline.details.status.text,
      );
    });
  });

  describe('information column', () => {
    beforeEach(() => {
      wrapper = createWrapper(pipeline);
    });

    it('should render a pipeline link', () => {
      expect(wrapper.find('.table-section:nth-child(2) a').attributes('href')).toEqual(
        pipeline.path,
      );
    });

    it('should render pipeline ID', () => {
      expect(wrapper.find('.table-section:nth-child(2) a > span').text()).toEqual(
        `#${pipeline.id}`,
      );
    });

    describe('when a user is provided', () => {
      it('should render user information', () => {
        expect(
          wrapper.find('.table-section:nth-child(3) .js-pipeline-url-user').attributes('href'),
        ).toEqual(pipeline.user.path);

        expect(
          wrapper.find('.table-section:nth-child(3) .js-user-avatar-image-tooltip').text().trim(),
        ).toEqual(pipeline.user.name);
      });
    });
  });

  describe('commit column', () => {
    it('should render link to commit', () => {
      wrapper = createWrapper(pipeline);

      const commitLink = wrapper.find('.branch-commit .commit-sha');

      expect(commitLink.attributes('href')).toEqual(pipeline.commit.commit_path);
    });

    const findElements = () => {
      const commitTitleElement = wrapper.find('.branch-commit .commit-title');
      const commitAuthorElement = commitTitleElement.find('a.avatar-image-container');

      if (!commitAuthorElement.exists()) {
        return {
          commitAuthorElement,
        };
      }

      const commitAuthorLink = commitAuthorElement.attributes('href');
      const commitAuthorName = commitAuthorElement
        .find('.js-user-avatar-image-tooltip')
        .text()
        .trim();

      return {
        commitAuthorElement,
        commitAuthorLink,
        commitAuthorName,
      };
    };

    it('renders nothing without commit', () => {
      expect(pipelineWithoutCommit.commit).toBe(null);

      wrapper = createWrapper(pipelineWithoutCommit);
      const { commitAuthorElement } = findElements();

      expect(commitAuthorElement.exists()).toBe(false);
    });

    it('renders commit author', () => {
      wrapper = createWrapper(pipeline);
      const { commitAuthorLink, commitAuthorName } = findElements();

      expect(commitAuthorLink).toEqual(pipeline.commit.author.path);
      expect(commitAuthorName).toEqual(pipeline.commit.author.username);
    });

    it('renders commit with unregistered author', () => {
      expect(pipelineWithoutAuthor.commit.author).toBe(null);

      wrapper = createWrapper(pipelineWithoutAuthor);
      const { commitAuthorLink, commitAuthorName } = findElements();

      expect(commitAuthorLink).toEqual(`mailto:${pipelineWithoutAuthor.commit.author_email}`);
      expect(commitAuthorName).toEqual(pipelineWithoutAuthor.commit.author_name);
    });
  });

  describe('stages column', () => {
    const findAllMiniPipelineStages = () =>
      wrapper.findAll('.table-section:nth-child(5) [data-testid="mini-pipeline-graph-dropdown"]');

    it('should render an icon for each stage', () => {
      wrapper = createWrapper(pipeline);

      expect(findAllMiniPipelineStages()).toHaveLength(pipeline.details.stages.length);
    });

    it('should not render stages when stages are empty', () => {
      const withoutStages = { ...pipeline };
      withoutStages.details = { ...withoutStages.details, stages: null };

      wrapper = createWrapper(withoutStages);

      expect(findAllMiniPipelineStages()).toHaveLength(0);
    });
  });

  describe('actions column', () => {
    const scheduledJobAction = {
      name: 'some scheduled job',
    };

    beforeEach(() => {
      const withActions = { ...pipeline };
      withActions.details.scheduled_actions = [scheduledJobAction];
      withActions.flags.cancelable = true;
      withActions.flags.retryable = true;
      withActions.cancel_path = '/cancel';
      withActions.retry_path = '/retry';

      wrapper = createWrapper(withActions);
    });

    it('should render the provided actions', () => {
      expect(wrapper.find('.js-pipelines-retry-button').exists()).toBe(true);
      expect(wrapper.find('.js-pipelines-retry-button').attributes('title')).toMatch('Retry');
      expect(wrapper.find('.js-pipelines-cancel-button').exists()).toBe(true);
      expect(wrapper.find('.js-pipelines-cancel-button').attributes('title')).toMatch('Cancel');
    });

    it('should render the manual actions', async () => {
      const manualActions = wrapper.find('[data-testid="pipelines-manual-actions-dropdown"]');

      // Click on the dropdown and wait for `lazy` dropdown items
      manualActions.find('.dropdown-toggle').trigger('click');
      await waitForPromises();

      expect(manualActions.text()).toContain(scheduledJobAction.name);
    });

    it('emits `retryPipeline` event when retry button is clicked and toggles loading', () => {
      eventHub.$on('retryPipeline', (endpoint) => {
        expect(endpoint).toBe('/retry');
      });

      wrapper.find('.js-pipelines-retry-button').trigger('click');
      expect(wrapper.vm.isRetrying).toBe(true);
    });

    it('emits `openConfirmationModal` event when cancel button is clicked and toggles loading', () => {
      eventHub.$once('openConfirmationModal', (data) => {
        const { id, ref, commit } = pipeline;

        expect(data.endpoint).toBe('/cancel');
        expect(data.pipeline).toEqual(
          expect.objectContaining({
            id,
            ref,
            commit,
          }),
        );
      });

      wrapper.find('.js-pipelines-cancel-button').trigger('click');
    });

    it('renders a loading icon when `cancelingPipeline` matches pipeline id', (done) => {
      wrapper.setProps({ cancelingPipeline: pipeline.id });
      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.vm.isCancelling).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
