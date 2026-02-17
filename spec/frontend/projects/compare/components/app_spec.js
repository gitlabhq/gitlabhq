import { GlIcon, GlLink, GlSprintf, GlFormGroup, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CompareApp from '~/projects/compare/components/app.vue';
import {
  COMPARE_REVISIONS_DOCS_URL,
  I18N,
  COMPARE_OPTIONS,
  COMPARE_OPTIONS_INPUT_NAME,
} from '~/projects/compare/constants';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import RevisionCard from '~/projects/compare/components/revision_card.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { appDefaultProps as defaultProps } from './mock_data';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('CompareApp component', () => {
  let wrapper;
  const findSourceRevisionCard = () => wrapper.findByTestId('sourceRevisionCard');
  const findTargetRevisionCard = () => wrapper.findByTestId('targetRevisionCard');
  const findPageTitle = () => wrapper.findByTestId('page-heading');
  const findPageDescription = () => wrapper.findByTestId('page-heading-description');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CompareApp, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        GlSprintf,
        GlFormRadioGroup,
        PageHeading,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders component with prop', () => {
    expect(wrapper.props()).toEqual(
      expect.objectContaining({
        projectCompareIndexPath: defaultProps.projectCompareIndexPath,
        sourceProjectRefsPath: defaultProps.sourceProjectRefsPath,
        targetProjectRefsPath: defaultProps.targetProjectRefsPath,
        paramsFrom: defaultProps.paramsFrom,
        paramsTo: defaultProps.paramsTo,
      }),
    );
  });

  it('renders title', () => {
    expect(findPageTitle().text()).toBe(I18N.title);
  });

  it('renders description', () => {
    expect(findPageDescription().text()).toMatchInterpolatedText(I18N.subtitle);
  });

  it('renders link to docs', () => {
    const docsLink = wrapper.findComponent(GlLink);
    expect(docsLink.attributes('href')).toBe(COMPARE_REVISIONS_DOCS_URL);
  });

  it('contains the correct form attributes', () => {
    expect(wrapper.attributes('action')).toBe(defaultProps.projectCompareIndexPath);
    expect(wrapper.attributes('method')).toBe('POST');
  });

  it('has input with csrf token', () => {
    expect(wrapper.find('input[name="authenticity_token"]').attributes('value')).toBe(
      'mock-csrf-token',
    );
  });

  it('render Source and Target BranchDropdown components', () => {
    const revisionCards = wrapper.findAllComponents(RevisionCard);

    expect(revisionCards).toHaveLength(2);
    expect(revisionCards.at(0).props('revisionText')).toBe(I18N.source);
    expect(revisionCards.at(1).props('revisionText')).toBe(I18N.target);
  });

  describe('compare button', () => {
    const findCompareButton = () => wrapper.findByTestId('compare-button');

    it('renders button', () => {
      expect(findCompareButton().exists()).toBe(true);
    });

    it('has compare text', () => {
      expect(findCompareButton().text()).toBe('Compare');
    });
  });

  it('sets the selected project when the "selectProject" event is emitted', async () => {
    const project = {
      name: 'some-to-name',
      id: '1',
      refs_url: '/',
    };

    findTargetRevisionCard().vm.$emit('selectProject', {
      direction: 'from',
      project,
    });

    await nextTick();

    expect(findTargetRevisionCard().props('selectedProject')).toEqual(
      expect.objectContaining(project),
    );
  });

  it('sets the selected revision when the "selectRevision" event is emitted', async () => {
    const revision = 'some-revision';

    findTargetRevisionCard().vm.$emit('selectRevision', {
      direction: 'to',
      revision,
    });

    await nextTick();

    expect(findSourceRevisionCard().props('paramsBranch')).toBe(revision);
  });

  describe('swap revisions button', () => {
    const findSwapRevisionsButton = () => wrapper.findByTestId('swapRevisionsButton');

    it('renders the swap revisions button', () => {
      expect(findSwapRevisionsButton().exists()).toBe(true);
    });

    it('renders icon', () => {
      expect(findSwapRevisionsButton().findComponent(GlIcon).props('name')).toBe('substitute');
    });

    it('has tooltip', () => {
      const tooltip = getBinding(findSwapRevisionsButton().element, 'gl-tooltip');
      expect(tooltip.value).toBe(I18N.swapRevisions);
    });

    it('swaps revisions when clicked', async () => {
      findSwapRevisionsButton().vm.$emit('click');

      await nextTick();

      expect(findTargetRevisionCard().props('paramsBranch')).toBe(defaultProps.paramsTo);
      expect(findSourceRevisionCard().props('paramsBranch')).toBe(defaultProps.paramsFrom);
    });
  });

  describe('compare options', () => {
    const findGroup = () => wrapper.findComponent(GlFormGroup);
    const findOptionsGroup = () => wrapper.findComponent(GlFormRadioGroup);

    const findOptions = () => wrapper.findAllComponents(GlFormRadio);

    it('renders label for the compare options', () => {
      expect(findGroup().attributes('label')).toBe(I18N.optionsLabel);
    });

    it('correct input name', () => {
      expect(findOptionsGroup().attributes('name')).toBe(COMPARE_OPTIONS_INPUT_NAME);
    });

    it('renders "only incoming changes" option', () => {
      expect(findOptions().at(0).text()).toBe(COMPARE_OPTIONS[0].text);
    });

    it('renders "since source was created" option', () => {
      expect(findOptions().at(1).text()).toBe(COMPARE_OPTIONS[1].text);
    });

    it('straight mode button when clicked', async () => {
      expect(wrapper.props('straight')).toBe(false);
      expect(wrapper.vm.isStraight).toBe(false);

      findOptionsGroup().vm.$emit('input', COMPARE_OPTIONS[1].value);

      await nextTick();

      expect(wrapper.vm.isStraight).toBe(true);
    });
  });

  describe('merge request buttons', () => {
    const findProjectMrButton = () => wrapper.findByTestId('projectMrButton');
    const findCreateMrButton = () => wrapper.findByTestId('createMrButton');
    const findMrStatusMessage = () => wrapper.findByTestId('mrStatusMessage');

    it('does not have merge request buttons', () => {
      expect(findProjectMrButton().exists()).toBe(false);
      expect(findCreateMrButton().exists()).toBe(false);
      expect(findMrStatusMessage().exists()).toBe(false);
    });

    it('has "View open merge request" button', () => {
      createComponent({
        projectMergeRequestPath: 'some/project/merge/request/path',
      });
      expect(findProjectMrButton().exists()).toBe(true);
      expect(findCreateMrButton().exists()).toBe(false);
      expect(findMrStatusMessage().exists()).toBe(false);
    });

    it('has "Create merge request" button', () => {
      createComponent({
        createMrPath: 'some/create/create/mr/path',
      });
      expect(findProjectMrButton().exists()).toBe(false);
      expect(findCreateMrButton().exists()).toBe(true);
      expect(findMrStatusMessage().exists()).toBe(false);
    });

    describe('when branch selection changes', () => {
      describe.each`
        mrPathType                   | propsData
        ${'projectMergeRequestPath'} | ${{ projectMergeRequestPath: 'some/project/merge/request/path' }}
        ${'createMrPath'}            | ${{ createMrPath: 'some/create/mr/path' }}
      `('with $mrPathType', ({ propsData }) => {
        beforeEach(() => {
          createComponent(propsData);
        });

        it.each`
          changeType          | action
          ${'source branch'}  | ${() => findSourceRevisionCard().vm.$emit('selectRevision', { direction: 'to', revision: 'new-source-branch' })}
          ${'target branch'}  | ${() => findTargetRevisionCard().vm.$emit('selectRevision', { direction: 'from', revision: 'new-target-branch' })}
          ${'swap revisions'} | ${() => wrapper.findByTestId('swapRevisionsButton').vm.$emit('click')}
        `('replaces button with message when $changeType changes', async ({ action }) => {
          expect(findProjectMrButton().exists() || findCreateMrButton().exists()).toBe(true);
          expect(findMrStatusMessage().exists()).toBe(false);

          action();
          await nextTick();

          expect(findProjectMrButton().exists()).toBe(false);
          expect(findCreateMrButton().exists()).toBe(false);
          expect(findMrStatusMessage().exists()).toBe(true);
          expect(findMrStatusMessage().text()).toBe(
            'Select Compare to check for an existing merge request',
          );
        });

        it('shows button again when branches are changed back to original values', async () => {
          findSourceRevisionCard().vm.$emit('selectRevision', {
            direction: 'to',
            revision: 'different-branch',
          });
          await nextTick();
          expect(findProjectMrButton().exists()).toBe(false);
          expect(findCreateMrButton().exists()).toBe(false);
          expect(findMrStatusMessage().exists()).toBe(true);

          findSourceRevisionCard().vm.$emit('selectRevision', {
            direction: 'to',
            revision: defaultProps.paramsTo,
          });
          await nextTick();

          expect(findProjectMrButton().exists() || findCreateMrButton().exists()).toBe(true);
          expect(findMrStatusMessage().exists()).toBe(false);
        });
      });

      describe('when page loads without MR paths (same source/target)', () => {
        beforeEach(() => {
          createComponent({
            projectMergeRequestPath: '',
            createMrPath: '',
          });
        });

        it('shows message when branches change to be different', async () => {
          expect(findProjectMrButton().exists()).toBe(false);
          expect(findCreateMrButton().exists()).toBe(false);
          expect(findMrStatusMessage().exists()).toBe(false);

          findSourceRevisionCard().vm.$emit('selectRevision', {
            direction: 'to',
            revision: 'new-branch',
          });

          await nextTick();

          expect(findMrStatusMessage().exists()).toBe(true);
          expect(findMrStatusMessage().text()).toBe(
            'Select Compare to check for an existing merge request',
          );
        });
      });

      describe('when branches have same value', () => {
        beforeEach(() => {
          createComponent({
            paramsFrom: 'main',
            paramsTo: 'main',
            projectMergeRequestPath: '',
            createMrPath: '',
          });
        });

        it('does not show message when swapping identical branches', async () => {
          expect(findMrStatusMessage().exists()).toBe(false);

          wrapper.findByTestId('swapRevisionsButton').vm.$emit('click');

          await nextTick();

          expect(findMrStatusMessage().exists()).toBe(false);
        });

        it('shows message when changing to a different branch', async () => {
          findSourceRevisionCard().vm.$emit('selectRevision', {
            direction: 'to',
            revision: 'feature-branch',
          });

          await nextTick();

          expect(findMrStatusMessage().exists()).toBe(true);
          expect(findMrStatusMessage().text()).toBe(
            'Select Compare to check for an existing merge request',
          );
        });
      });
    });
  });
});
