import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CompareApp from '~/projects/compare/components/app_legacy.vue';
import RevisionDropdown from '~/projects/compare/components/revision_dropdown_legacy.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const projectCompareIndexPath = 'some/path';
const refsProjectPath = 'some/refs/path';
const paramsFrom = 'main';
const paramsTo = 'some-other-branch';

describe('CompareApp component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CompareApp, {
      propsData: {
        projectCompareIndexPath,
        refsProjectPath,
        paramsFrom,
        paramsTo,
        projectMergeRequestPath: '',
        createMrPath: '',
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

  const findSourceDropdown = () => wrapper.find('[data-testid="sourceRevisionDropdown"]');
  const findTargetDropdown = () => wrapper.find('[data-testid="targetRevisionDropdown"]');

  it('renders component with prop', () => {
    expect(wrapper.props()).toEqual(
      expect.objectContaining({
        projectCompareIndexPath,
        refsProjectPath,
        paramsFrom,
        paramsTo,
      }),
    );
  });

  it('contains the correct form attributes', () => {
    expect(wrapper.attributes('action')).toBe(projectCompareIndexPath);
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

  describe('Source and Target BranchDropdown components', () => {
    const findAllBranchDropdowns = () => wrapper.findAll(RevisionDropdown);

    it('renders the components with the correct props', () => {
      expect(findAllBranchDropdowns().length).toBe(2);
      expect(findSourceDropdown().props('revisionText')).toBe('Source');
      expect(findTargetDropdown().props('revisionText')).toBe('Target');
    });

    it('sets the revision when the "selectRevision" event is emitted', async () => {
      findSourceDropdown().vm.$emit('selectRevision', {
        direction: 'to',
        revision: 'some-source-revision',
      });

      findTargetDropdown().vm.$emit('selectRevision', {
        direction: 'from',
        revision: 'some-target-revision',
      });

      await wrapper.vm.$nextTick();

      expect(findTargetDropdown().props('paramsBranch')).toBe('some-target-revision');
      expect(findSourceDropdown().props('paramsBranch')).toBe('some-source-revision');
    });
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

      expect(findTargetDropdown().props('paramsBranch')).toBe(paramsTo);
      expect(findSourceDropdown().props('paramsBranch')).toBe(paramsFrom);
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
