import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import StagesDropdown from '~/jobs/components/stages_dropdown.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import {
  mockPipelineWithoutMR,
  mockPipelineWithAttachedMR,
  mockPipelineDetached,
} from '../mock_data';

describe('Stages Dropdown', () => {
  let wrapper;

  const findStatus = () => wrapper.findComponent(CiIcon);
  const findSelectedStageText = () => wrapper.findComponent(GlDropdown).props('text');
  const findStageItem = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);

  const findPipelineInfoText = () => wrapper.findByTestId('pipeline-info').text();
  const findPipelinePath = () => wrapper.findByTestId('pipeline-path').attributes('href');
  const findMRLinkPath = () => wrapper.findByTestId('mr-link').attributes('href');
  const findSourceBranchLinkPath = () =>
    wrapper.findByTestId('source-branch-link').attributes('href');
  const findTargetBranchLinkPath = () =>
    wrapper.findByTestId('target-branch-link').attributes('href');

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      shallowMount(StagesDropdown, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('without a merge request pipeline', () => {
    beforeEach(() => {
      createComponent({
        pipeline: mockPipelineWithoutMR,
        stages: [{ name: 'build' }, { name: 'test' }],
        selectedStage: 'deploy',
      });
    });

    it('renders pipeline status', () => {
      expect(findStatus().exists()).toBe(true);
    });

    it('renders pipeline link', () => {
      expect(findPipelinePath()).toBe('pipeline/28029444');
    });

    it('renders dropdown with stages', () => {
      expect(findStageItem(0).text()).toBe('build');
    });

    it('rendes selected stage', () => {
      expect(findSelectedStageText()).toBe('deploy');
    });

    it(`renders the pipeline info text like "Pipeline #123 for source_branch"`, () => {
      const expected = `Pipeline #${mockPipelineWithoutMR.id} for ${mockPipelineWithoutMR.ref.name}`;
      const actual = trimText(findPipelineInfoText());

      expect(actual).toBe(expected);
    });
  });

  describe('with an "attached" merge request pipeline', () => {
    beforeEach(() => {
      createComponent({
        pipeline: mockPipelineWithAttachedMR,
        stages: [],
        selectedStage: 'deploy',
      });
    });

    it(`renders the pipeline info text like "Pipeline #123 for !456 with source_branch into target_branch"`, () => {
      const expected = `Pipeline #${mockPipelineWithAttachedMR.id} for !${mockPipelineWithAttachedMR.merge_request.iid} with ${mockPipelineWithAttachedMR.merge_request.source_branch} into ${mockPipelineWithAttachedMR.merge_request.target_branch}`;
      const actual = trimText(findPipelineInfoText());

      expect(actual).toBe(expected);
    });

    it(`renders the correct merge request link`, () => {
      expect(findMRLinkPath()).toBe(mockPipelineWithAttachedMR.merge_request.path);
    });

    it(`renders the correct source branch link`, () => {
      expect(findSourceBranchLinkPath()).toBe(
        mockPipelineWithAttachedMR.merge_request.source_branch_path,
      );
    });

    it(`renders the correct target branch link`, () => {
      expect(findTargetBranchLinkPath()).toBe(
        mockPipelineWithAttachedMR.merge_request.target_branch_path,
      );
    });
  });

  describe('with a detached merge request pipeline', () => {
    beforeEach(() => {
      createComponent({
        pipeline: mockPipelineDetached,
        stages: [],
        selectedStage: 'deploy',
      });
    });

    it(`renders the pipeline info like "Pipeline #123 for !456 with source_branch"`, () => {
      const expected = `Pipeline #${mockPipelineDetached.id} for !${mockPipelineDetached.merge_request.iid} with ${mockPipelineDetached.merge_request.source_branch}`;
      const actual = trimText(findPipelineInfoText());

      expect(actual).toBe(expected);
    });

    it(`renders the correct merge request link`, () => {
      expect(findMRLinkPath()).toBe(mockPipelineDetached.merge_request.path);
    });

    it(`renders the correct source branch link`, () => {
      expect(findSourceBranchLinkPath()).toBe(
        mockPipelineDetached.merge_request.source_branch_path,
      );
    });
  });
});
