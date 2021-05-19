import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CompareApp from '~/projects/compare/components/app.vue';
import RevisionCard from '~/projects/compare/components/revision_card.vue';
import { appDefaultProps as defaultProps } from './mock_data';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('CompareApp component', () => {
  let wrapper;
  const findSourceRevisionCard = () => wrapper.find('[data-testid="sourceRevisionCard"]');
  const findTargetRevisionCard = () => wrapper.find('[data-testid="targetRevisionCard"]');

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CompareApp, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
  });

  it('renders component with prop', () => {
    expect(wrapper.props()).toEqual(
      expect.objectContaining({
        projectCompareIndexPath: defaultProps.projectCompareIndexPath,
        refsProjectPath: defaultProps.refsProjectPath,
        paramsFrom: defaultProps.paramsFrom,
        paramsTo: defaultProps.paramsTo,
      }),
    );
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

  it('has ellipsis', () => {
    expect(wrapper.find('[data-testid="ellipsis"]').exists()).toBe(true);
  });

  it('render Source and Target BranchDropdown components', () => {
    const revisionCards = wrapper.findAll(RevisionCard);

    expect(revisionCards.length).toBe(2);
    expect(revisionCards.at(0).props('revisionText')).toBe('Source');
    expect(revisionCards.at(1).props('revisionText')).toBe('Target');
  });

  describe('compare button', () => {
    const findCompareButton = () => wrapper.find(GlButton);

    it('renders button', () => {
      expect(findCompareButton().exists()).toBe(true);
    });

    it('submits form', () => {
      findCompareButton().vm.$emit('click');
      expect(wrapper.find('form').element.submit).toHaveBeenCalled();
    });

    it('has compare text', () => {
      expect(findCompareButton().text()).toBe('Compare');
    });
  });

  it('sets the selected project when the "selectProject" event is emitted', async () => {
    const project = {
      name: 'some-to-name',
      id: '1',
    };

    findTargetRevisionCard().vm.$emit('selectProject', {
      direction: 'to',
      project,
    });

    await wrapper.vm.$nextTick();

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

    await wrapper.vm.$nextTick();

    expect(findSourceRevisionCard().props('paramsBranch')).toBe(revision);
  });

  describe('swap revisions button', () => {
    const findSwapRevisionsButton = () => wrapper.find('[data-testid="swapRevisionsButton"]');

    it('renders the swap revisions button', () => {
      expect(findSwapRevisionsButton().exists()).toBe(true);
    });

    it('has the correct text', () => {
      expect(findSwapRevisionsButton().text()).toBe('Swap revisions');
    });

    it('swaps revisions when clicked', async () => {
      findSwapRevisionsButton().vm.$emit('click');

      await wrapper.vm.$nextTick();

      expect(findTargetRevisionCard().props('paramsBranch')).toBe(defaultProps.paramsTo);
      expect(findSourceRevisionCard().props('paramsBranch')).toBe(defaultProps.paramsFrom);
    });
  });

  describe('merge request buttons', () => {
    const findProjectMrButton = () => wrapper.find('[data-testid="projectMrButton"]');
    const findCreateMrButton = () => wrapper.find('[data-testid="createMrButton"]');

    it('does not have merge request buttons', () => {
      createComponent();
      expect(findProjectMrButton().exists()).toBe(false);
      expect(findCreateMrButton().exists()).toBe(false);
    });

    it('has "View open merge request" button', () => {
      createComponent({
        projectMergeRequestPath: 'some/project/merge/request/path',
      });
      expect(findProjectMrButton().exists()).toBe(true);
      expect(findCreateMrButton().exists()).toBe(false);
    });

    it('has "Create merge request" button', () => {
      createComponent({
        createMrPath: 'some/create/create/mr/path',
      });
      expect(findProjectMrButton().exists()).toBe(false);
      expect(findCreateMrButton().exists()).toBe(true);
    });
  });
});
