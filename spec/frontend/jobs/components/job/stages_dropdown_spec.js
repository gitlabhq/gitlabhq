import { GlDropdown, GlDropdownItem, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { Mousetrap } from '~/lib/mousetrap';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import StagesDropdown from '~/jobs/components/job/sidebar/stages_dropdown.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import * as copyToClipboard from '~/behaviors/copy_to_clipboard';
import {
  mockPipelineWithoutRef,
  mockPipelineWithoutMR,
  mockPipelineWithAttachedMR,
  mockPipelineDetached,
} from '../../mock_data';

describe('Stages Dropdown', () => {
  let wrapper;

  const findStatus = () => wrapper.findComponent(CiIcon);
  const findSelectedStageText = () => wrapper.findComponent(GlDropdown).props('text');
  const findStageItem = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);

  const findPipelineInfoText = () => wrapper.findByTestId('pipeline-info').text();

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      shallowMount(StagesDropdown, {
        propsData: {
          stages: [],
          selectedStage: 'deploy',
          ...props,
        },
        stubs: {
          GlSprintf,
          GlLink,
        },
      }),
    );
  };

  describe('without a merge request pipeline', () => {
    beforeEach(() => {
      createComponent({
        pipeline: mockPipelineWithoutMR,
        stages: [{ name: 'build' }, { name: 'test' }],
      });
    });

    it('renders pipeline status', () => {
      expect(findStatus().exists()).toBe(true);
    });

    it('renders dropdown with stages', () => {
      expect(findStageItem(0).text()).toBe('build');
    });

    it('rendes selected stage', () => {
      expect(findSelectedStageText()).toBe('deploy');
    });
  });

  describe('pipelineInfo', () => {
    const allElements = [
      'pipeline-path',
      'mr-link',
      'source-ref-link',
      'copy-source-ref-link',
      'source-branch-link',
      'copy-source-branch-link',
      'target-branch-link',
      'copy-target-branch-link',
    ];
    describe.each([
      [
        'does not have a ref',
        {
          pipeline: mockPipelineWithoutRef,
          text: `Pipeline #${mockPipelineWithoutRef.id}`,
          foundElements: [
            { testId: 'pipeline-path', props: [{ href: mockPipelineWithoutRef.path }] },
          ],
        },
      ],
      [
        'hasRef but not triggered by MR',
        {
          pipeline: mockPipelineWithoutMR,
          text: `Pipeline #${mockPipelineWithoutMR.id} for ${mockPipelineWithoutMR.ref.name}`,
          foundElements: [
            { testId: 'pipeline-path', props: [{ href: mockPipelineWithoutMR.path }] },
            { testId: 'source-ref-link', props: [{ href: mockPipelineWithoutMR.ref.path }] },
            { testId: 'copy-source-ref-link', props: [{ text: mockPipelineWithoutMR.ref.name }] },
          ],
        },
      ],
      [
        'hasRef and MR but not MR pipeline',
        {
          pipeline: mockPipelineDetached,
          text: `Pipeline #${mockPipelineDetached.id} for !${mockPipelineDetached.merge_request.iid} with ${mockPipelineDetached.merge_request.source_branch}`,
          foundElements: [
            { testId: 'pipeline-path', props: [{ href: mockPipelineDetached.path }] },
            { testId: 'mr-link', props: [{ href: mockPipelineDetached.merge_request.path }] },
            {
              testId: 'source-branch-link',
              props: [{ href: mockPipelineDetached.merge_request.source_branch_path }],
            },
            {
              testId: 'copy-source-branch-link',
              props: [{ text: mockPipelineDetached.merge_request.source_branch }],
            },
          ],
        },
      ],
      [
        'hasRef and MR and MR pipeline',
        {
          pipeline: mockPipelineWithAttachedMR,
          text: `Pipeline #${mockPipelineWithAttachedMR.id} for !${mockPipelineWithAttachedMR.merge_request.iid} with ${mockPipelineWithAttachedMR.merge_request.source_branch} into ${mockPipelineWithAttachedMR.merge_request.target_branch}`,
          foundElements: [
            { testId: 'pipeline-path', props: [{ href: mockPipelineWithAttachedMR.path }] },
            { testId: 'mr-link', props: [{ href: mockPipelineWithAttachedMR.merge_request.path }] },
            {
              testId: 'source-branch-link',
              props: [{ href: mockPipelineWithAttachedMR.merge_request.source_branch_path }],
            },
            {
              testId: 'copy-source-branch-link',
              props: [{ text: mockPipelineWithAttachedMR.merge_request.source_branch }],
            },
            {
              testId: 'target-branch-link',
              props: [{ href: mockPipelineWithAttachedMR.merge_request.target_branch_path }],
            },
            {
              testId: 'copy-target-branch-link',
              props: [{ text: mockPipelineWithAttachedMR.merge_request.target_branch }],
            },
          ],
        },
      ],
    ])('%s', (_, { pipeline, text, foundElements }) => {
      beforeEach(() => {
        createComponent({
          pipeline,
        });
      });

      it('should render the text', () => {
        expect(findPipelineInfoText()).toMatchInterpolatedText(text);
      });

      it('should find components with props', () => {
        foundElements.forEach((element) => {
          element.props.forEach((prop) => {
            const key = Object.keys(prop)[0];
            expect(wrapper.findByTestId(element.testId).attributes(key)).toBe(prop[key]);
          });
        });
      });

      it('should not find components', () => {
        const foundTestIds = foundElements.map((element) => element.testId);
        allElements
          .filter((testId) => !foundTestIds.includes(testId))
          .forEach((testId) => {
            expect(wrapper.findByTestId(testId).exists()).toBe(false);
          });
      });
    });
  });

  describe('mousetrap', () => {
    it.each([
      ['copy-source-ref-link', mockPipelineWithoutMR],
      ['copy-source-branch-link', mockPipelineWithAttachedMR],
    ])(
      'calls clickCopyToClipboardButton with `%s` button when `b` is pressed',
      (button, pipeline) => {
        const copyToClipboardMock = jest.spyOn(copyToClipboard, 'clickCopyToClipboardButton');
        createComponent({ pipeline });

        Mousetrap.trigger('b');

        expect(copyToClipboardMock).toHaveBeenCalledWith(wrapper.findByTestId(button).element);
      },
    );
  });
});
