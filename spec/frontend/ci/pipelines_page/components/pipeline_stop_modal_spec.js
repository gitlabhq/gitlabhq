import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PipelineStopModal from '~/ci/pipelines_page/components/pipeline_stop_modal.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { mockGetPipelinesResponse } from '../mock_data';

describe('PipelineStopModal', () => {
  let wrapper;

  const [mockPipelineNode] = mockGetPipelinesResponse.data.project.pipelines.nodes;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(PipelineStopModal, {
      propsData: {
        pipeline: mockPipelineNode,
        showConfirmationModal: false,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findPipelineLink = () => wrapper.findByTestId('pipeline-path');
  const findRefLink = () => wrapper.findByTestId('pipeline-ref');
  const findCommitLink = () => wrapper.findByTestId('commit-sha');
  const findStatusIcon = () => wrapper.findComponent(CiIcon);

  const pipelineId = getIdFromGraphQLId(mockPipelineNode.id);

  beforeEach(() => {
    createComponent();
  });

  describe('when `showConfirmationModal` is false', () => {
    it('passes the visibility value to the modal', () => {
      expect(findModal().props().visible).toBe(false);
    });
  });

  describe('when `showConfirmationModal` is true', () => {
    beforeEach(() => {
      createComponent({ props: { showConfirmationModal: true } });
    });

    it('passes the visibility value to the modal', () => {
      expect(findModal().props().visible).toBe(true);
    });

    it('renders "stop pipeline" warning', () => {
      expect(wrapper.text()).toMatch(`You're about to stop pipeline #${pipelineId}.`);
    });

    it('renders the numeric id in the modal title', () => {
      expect(findModal().props('title')).toBe(`Stop pipeline #${pipelineId}?`);
    });

    it('renders a link to the pipeline', () => {
      expect(findPipelineLink().text()).toBe(`#${pipelineId}`);
      expect(findPipelineLink().attributes('href')).toBe(mockPipelineNode.path);
    });

    it('renders the commit sha and link', () => {
      expect(findCommitLink().text()).toBe(mockPipelineNode.commit.shortId);
      expect(findCommitLink().attributes('href')).toBe(mockPipelineNode.commit.webPath);
    });

    it('renders the status icon', () => {
      expect(findStatusIcon().props('status')).toBe(mockPipelineNode.detailedStatus);
    });
  });

  describe.each`
    refShape         | ref                              | refPath                 | sourceRef
    ${'a branch'}    | ${'main'}                        | ${'refs/heads/main'}    | ${'main'}
    ${'a tag'}       | ${'v1.0'}                        | ${'refs/tags/v1.0'}     | ${'v1.0'}
    ${'a merge ref'} | ${'refs/merge-requests/1/merge'} | ${'refs/heads/feature'} | ${'feature'}
    ${'only a ref'}  | ${'main'}                        | ${null}                 | ${'main'}
  `('when the pipeline has $refShape', ({ ref, refPath, sourceRef }) => {
    beforeEach(() => {
      createComponent({
        props: {
          showConfirmationModal: true,
          pipeline: { ...mockPipelineNode, ref, refPath },
        },
      });
    });

    it('renders the source ref and links to its commits path', () => {
      expect(findRefLink().text()).toBe(sourceRef);
      expect(findRefLink().attributes('href')).toBe(
        `/${mockPipelineNode.project.fullPath}/-/commits/${sourceRef}`,
      );
    });
  });

  describe.each`
    refShape         | ref                              | refUrl
    ${'a branch'}    | ${'main'}                        | ${'/root/ci-project/-/commits/main'}
    ${'a merge ref'} | ${'refs/merge-requests/1/merge'} | ${'/root/ci-project/-/commits/refs/merge-requests/1/merge'}
  `('when the pipeline provides a ref URL for $refShape', ({ ref, refUrl }) => {
    beforeEach(() => {
      createComponent({
        props: {
          showConfirmationModal: true,
          pipeline: { ...mockPipelineNode, ref, refPath: null, refUrl },
        },
      });
    });

    it('renders the ref and URL unchanged', () => {
      expect(findRefLink().text()).toBe(ref);
      expect(findRefLink().attributes('href')).toBe(refUrl);
    });
  });

  describe('when the pipeline has no ref, commit or status', () => {
    beforeEach(() => {
      createComponent({
        props: {
          showConfirmationModal: true,
          pipeline: { id: mockPipelineNode.id, path: mockPipelineNode.path },
        },
      });
    });

    it('does not render the ref link', () => {
      expect(findRefLink().exists()).toBe(false);
    });

    it('does not render the commit link', () => {
      expect(findCommitLink().exists()).toBe(false);
    });

    it('does not render the status icon', () => {
      expect(findStatusIcon().exists()).toBe(false);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent({ props: { showConfirmationModal: true } });
    });

    it('emits the close-modal event when the visibility changes', async () => {
      expect(wrapper.emitted('close-modal')).toBeUndefined();

      await findModal().vm.$emit('change', false);

      expect(wrapper.emitted('close-modal')).toEqual([[]]);
    });
  });
});
