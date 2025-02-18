import { GlBadge, GlButton, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CandidateHeader from '~/ml/experiment_tracking/routes/candidates/show/candidate_header.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { newCandidate } from 'jest/ml/model_registry/mock_data';

describe('ml/experiment_tracking/routes/candidates/show/candidate_header.vue', () => {
  let wrapper;

  const defaultProps = {
    candidate: newCandidate(),
  };

  const createWrapper = (props = {}) => {
    return shallowMountExtended(CandidateHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findDeleteButton = () => wrapper.findComponent(DeleteButton);
  const findPromoteButton = () => wrapper.findComponent(GlButton);
  const findTimeAgo = () => wrapper.findComponent(TimeAgoTooltip);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findAuthorLink = () => wrapper.findByTestId('author-link');
  const findExperimentLink = () => wrapper.findByTestId('experiment-link');
  const findStatusIcon = () => wrapper.findComponent(GlIcon);

  describe('Basic rendering', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders the page heading with correct title', () => {
      expect(findPageHeading().text()).toContain('Run candidate_iid');
    });

    it('renders the experiment name with link', () => {
      expect(findExperimentLink().text()).toBe('The Experiment /');
      expect(findExperimentLink().attributes('href')).toBe('path/to/experiment');
    });

    it('renders the time ago component with correct timestamp', () => {
      expect(findTimeAgo().props('time')).toBe('2024-01-01T00:00:00Z');
    });

    it('renders the status badge with correct variant', () => {
      expect(findBadge().props('variant')).toBe('muted');
      expect(findBadge().text()).toContain('SUCCESS');
    });

    it('renders the status icon', () => {
      expect(findStatusIcon().exists()).toBe(true);
      expect(findStatusIcon().props('name')).toBe('issue-type-test-case');
    });

    it('renders the author information', () => {
      const authorLink = findAuthorLink();
      expect(authorLink.attributes('href')).toBe('/test-user');
      expect(authorLink.text()).toContain('by Test User');
    });

    it('renders the delete button component', () => {
      const deleteButton = findDeleteButton();
      expect(deleteButton.exists()).toBe(true);
      expect(deleteButton.props('deletePath')).toBe('path_to_candidate');
    });
  });

  describe('Status variants', () => {
    const testCases = [
      { status: 'running', variant: 'success' },
      { status: 'scheduled', variant: 'info' },
      { status: 'finished', variant: 'muted' },
      { status: 'failed', variant: 'warning' },
      { status: 'killed', variant: 'danger' },
    ];

    testCases.forEach(({ status, variant }) => {
      it(`renders correct badge variant for ${status} status`, () => {
        wrapper = createWrapper({
          candidate: {
            ...defaultProps.candidate,
            info: {
              ...defaultProps.candidate.info,
              status,
            },
          },
        });

        expect(findBadge().props('variant')).toBe(variant);
      });
    });
  });

  describe('When author is not provided', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        candidate: {
          ...defaultProps.candidate,
          info: {
            ...defaultProps.candidate.info,
            authorName: null,
            authorWebUrl: null,
          },
        },
      });
    });

    it('does not render author link', () => {
      expect(findAuthorLink().exists()).toBe(false);
    });
  });

  describe('Delete button configuration', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('passes correct props to delete button', () => {
      const deleteButton = findDeleteButton();
      expect(deleteButton.props()).toMatchObject({
        deletePath: 'path_to_candidate',
        deleteConfirmationText:
          'Deleting this run will delete the associated parameters, metrics, and metadata.',
        actionPrimaryText: 'Delete run',
        modalTitle: 'Delete run?',
      });
    });
  });
  describe('When can not write to model experiments', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        candidate: {
          ...defaultProps.candidate,
          canWriteModelExperiments: false,
        },
      });
    });

    it('hides the delete button', () => {
      const deleteButton = findDeleteButton();
      expect(deleteButton.exists()).toBe(false);
    });
  });

  describe('Promote button', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('passes correct props to promote button', () => {
      expect(findPromoteButton().text()).toBe('Promote run');
      expect(findPromoteButton().attributes()).toMatchObject({
        href: 'promote/path',
      });
    });
  });
});
